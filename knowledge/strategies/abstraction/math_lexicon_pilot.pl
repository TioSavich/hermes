:- encoding(utf8).
/** <module> Demand-fit mathematics lexicon pilot
 *
 * Generated from repository demand sources by
 * scripts/language/build_math_lexicon.py. Each row keeps Webster
 * morphology beside counted demand evidence. Unknowns remain findings.
 *
 * Check from the repository root:
 * `swipl -q -l paths.pl -l knowledge/strategies/abstraction/math_lexicon_pilot.pl -g math_lexicon_pilot:check_math_lexicon_pilot -t halt`
 */
:- module(math_lexicon_pilot,
          [ ml_word/4, ml_unknown/2, ml_baseline_unknown/2, ml_source_term/3,
            math_lexicon_pilot_summary/1, check_math_lexicon_pilot/0
          ]).

:- use_module('english_morphology.pl').

% GENERATED FILE. Rebuild with scripts/language/build_math_lexicon.py; do not edit.
% question_records.jsonl sha256: 850410936db43d693527dc8d12ebb0e9e208f206ebf06206b8d20310bbe56026
% mistake_location_full.json sha256: eed1a4aad7681a2651010db014b2abec7af3fe4ff3ebd7f9f07984c3ae093c26
% scale_recurrence.py sha256: 39447baf6c2fa0a09a4fdfb4589461576f1b2c1877fff1cef2ea049d767ea684
% lexicon_supplement_pilot.pl sha256: 2fd972be923dce235df5d0b0b8a0ef61b2759e78df8ab8923e2ac76cd8883ffd

ml_word('able', verb, forms(['able', 'abled', 'ables', 'abling']), demand([question_corpus(6), dataset(86)])).
ml_word('able', adjective, forms(['able']), demand([question_corpus(6), dataset(86)])).
ml_word('above', adverb, forms(['above']), demand([question_corpus(1), dataset(23)])).
ml_word('above', preposition, forms(['above']), demand([question_corpus(1), dataset(23)])).
ml_word('absent', verb, forms(['absent', 'absented', 'absenting', 'absents']), demand([dataset(14)])).
ml_word('absent', adjective, forms(['absent']), demand([dataset(14)])).
ml_word('absolute', noun, forms(['absolute', 'absolutes']), demand([question_corpus(1), dataset(4), questioning_paper_lexicon, webster_domain('geom')])).
ml_word('absolute', adjective, forms(['absolute']), demand([question_corpus(1), dataset(4), questioning_paper_lexicon, webster_domain('geom')])).
ml_word('accept', verb, forms(['accept', 'accepted', 'accepting', 'accepts']), demand([dataset(10)])).
ml_word('accessory', noun, forms(['accessories', 'accessory']), demand([dataset(4)])).
ml_word('accident', noun, forms(['accident', 'accidents']), demand([dataset(2)])).
ml_word('accidentally', adverb, forms(['accidentally']), demand([dataset(3)])).
ml_word('accommodate', verb, forms(['accommodate', 'accommodated', 'accommodates', 'accommodating']), demand([dataset(5)])).
ml_word('accommodate', adjective, forms(['accommodate']), demand([dataset(5)])).
ml_word('accord', verb, forms(['accord', 'accorded', 'according', 'accords']), demand([dataset(14)])).
ml_word('according', adjective, forms(['according']), demand([dataset(14)])).
ml_word('according', adverb, forms(['according']), demand([dataset(14)])).
ml_word('account', noun, forms(['account', 'accounts']), demand([question_corpus(1), dataset(30)])).
ml_word('account', verb, forms(['account', 'accounted', 'accounting', 'accounts']), demand([question_corpus(2), dataset(34)])).
ml_word('accrue', verb, forms(['accrue', 'accrued', 'accrues', 'accruing']), demand([dataset(2)])).
ml_word('accurate', adjective, forms(['accurate']), demand([question_corpus(3)])).
ml_word('accurately', adverb, forms(['accurately']), demand([question_corpus(1)])).
ml_word('accuse', verb, forms(['accuse', 'accused', 'accuses', 'accusing']), demand([dataset(2)])).
ml_word('acorn', noun, forms(['acorn', 'acorns']), demand([dataset(14)])).
ml_word('acre', noun, forms(['acre', 'acres']), demand([dataset(9)])).
ml_word('across', adverb, forms(['across']), demand([question_corpus(3), dataset(45)])).
ml_word('act', noun, forms(['act', 'acts']), demand([question_corpus(2), dataset(10)])).
ml_word('act', verb, forms(['act', 'acted', 'acting', 'acts']), demand([question_corpus(2), dataset(10)])).
ml_word('action', noun, forms(['action', 'actions']), demand([question_corpus(2), dataset(2)])).
ml_word('activity', noun, forms(['activities', 'activity']), demand([question_corpus(2), dataset(9)])).
ml_word('actual', noun, forms(['actual', 'actuals']), demand([question_corpus(4), dataset(9)])).
ml_word('actually', adverb, forms(['actually']), demand([question_corpus(1), dataset(4)])).
ml_word('ad', noun, forms(['ad', 'ads']), demand([dataset(18), supplement_class('common_noun')])).
ml_word('adage', noun, forms(['adage', 'adages']), demand([dataset(3)])).
ml_word('adam', noun, forms(['adam', 'adams']), demand([dataset(9)])).
ml_word('add', verb, forms(['add', 'added', 'adding', 'adds']), demand([question_corpus(36), dataset(346)])).
ml_word('addend', noun, forms(['addend', 'addends']), demand([question_corpus(3), questioning_paper_lexicon, supplement_class('math_term')])).
ml_word('addition', noun, forms(['addition', 'additions']), demand([question_corpus(12), dataset(6), questioning_paper_lexicon])).
ml_word('additional', noun, forms(['additional', 'additionals']), demand([question_corpus(1), dataset(87)])).
ml_word('additional', adjective, forms(['additional']), demand([question_corpus(1), dataset(87)])).
ml_word('address', noun, forms(['address', 'addresses']), demand([dataset(36)])).
ml_word('address', verb, forms(['address', 'addressed', 'addresses', 'addressing']), demand([dataset(36)])).
ml_word('adjust', verb, forms(['adjust', 'adjusted', 'adjusting', 'adjusts']), demand([question_corpus(6)])).
ml_word('adopt', verb, forms(['adopt', 'adopted', 'adopting', 'adopts']), demand([dataset(6)])).
ml_word('adopted', adjective, forms(['adopted']), demand([dataset(6)])).
ml_word('adoption', noun, forms(['adoption', 'adoptions']), demand([dataset(5)])).
ml_word('adult', noun, forms(['adult', 'adults']), demand([question_corpus(2), dataset(78)])).
ml_word('adult', adjective, forms(['adult']), demand([question_corpus(2), dataset(63)])).
ml_word('advance', verb, forms(['advance', 'advanced', 'advances', 'advancing']), demand([question_corpus(1)])).
ml_word('advantage', noun, forms(['advantage', 'advantages']), demand([question_corpus(1)])).
ml_word('advantage', verb, forms(['advantage', 'advantaged', 'advantages', 'advantaging']), demand([question_corpus(1)])).
ml_word('advertise', verb, forms(['advertise', 'advertised', 'advertises', 'advertising']), demand([dataset(2)])).
ml_word('advice', noun, forms(['advice', 'advices']), demand([question_corpus(1)])).
ml_word('affect', noun, forms(['affect', 'affects']), demand([question_corpus(3)])).
ml_word('affect', verb, forms(['affect', 'affected', 'affecting', 'affects']), demand([question_corpus(3)])).
ml_word('afford', verb, forms(['afford', 'afforded', 'affording', 'affords']), demand([dataset(5)])).
ml_word('after', adjective, forms(['after']), demand([question_corpus(14), dataset(590)])).
ml_word('after', adverb, forms(['after']), demand([question_corpus(14), dataset(590)])).
ml_word('after', preposition, forms(['after']), demand([question_corpus(14), dataset(590)])).
ml_word('afternoon', noun, forms(['afternoon', 'afternoons']), demand([dataset(50)])).
ml_word('afterward', adverb, forms(['afterward']), demand([dataset(6)])).
ml_word('again', adverb, forms(['again']), demand([question_corpus(5), dataset(59)])).
ml_word('again', preposition, forms(['again']), demand([question_corpus(5), dataset(59)])).
ml_word('against', preposition, forms(['against']), demand([dataset(8)])).
ml_word('age', noun, forms(['age', 'ages']), demand([question_corpus(1), dataset(105)])).
ml_word('age', verb, forms(['age', 'aged', 'ages', 'aging']), demand([question_corpus(1), dataset(105)])).
ml_word('agnes', given_name, forms(['agnes']), demand([dataset(15), supplement_class('given_name')])).
ml_word('ago', adjective, forms(['ago']), demand([dataset(45)])).
ml_word('ago', adverb, forms(['ago']), demand([dataset(45)])).
ml_word('agree', verb, forms(['agree', 'agreed', 'agreeing', 'agrees']), demand([question_corpus(11), dataset(22)])).
ml_word('agree', adverb, forms(['agree']), demand([question_corpus(11), dataset(6)])).
ml_word('ahead', adverb, forms(['ahead']), demand([dataset(13)])).
ml_word('ahold', adverb, forms(['ahold']), demand([dataset(2)])).
ml_word('aid', noun, forms(['aid', 'aids']), demand([dataset(2)])).
ml_word('aid', verb, forms(['aid', 'aided', 'aiding', 'aids']), demand([dataset(2)])).
ml_word('aimee', given_name, forms(['aimee']), demand([dataset(4), supplement_class('given_name')])).
ml_word('air', noun, forms(['air', 'airs']), demand([dataset(15)])).
ml_word('air', verb, forms(['air', 'aired', 'airing', 'airs']), demand([dataset(15)])).
ml_word('aircraft', noun, forms(['aircraft', 'aircrafts']), demand([question_corpus(1)])).
ml_word('airline', noun, forms(['airline', 'airlines']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('airplane', noun, forms(['airplane', 'airplanes']), demand([question_corpus(1), dataset(35), supplement_class('common_noun')])).
ml_word('airport', noun, forms(['airport', 'airports']), demand([dataset(3), supplement_class('common_noun')])).
ml_word('airtight', adjective, forms(['airtight']), demand([dataset(4), supplement_class('adjective')])).
ml_word('alaskan', adjective, forms(['alaskan']), demand([dataset(2), supplement_class('adjective')])).
ml_word('album', noun, forms(['album', 'albums']), demand([dataset(23)])).
ml_word('alex', given_name, forms(['alex']), demand([dataset(21), supplement_class('given_name')])).
ml_word('algebra', noun, forms(['algebra', 'algebras']), demand([dataset(16)])).
ml_word('algorithm', noun, forms(['algorithm', 'algorithms']), demand([question_corpus(9)])).
ml_word('alice', given_name, forms(['alice']), demand([dataset(8), supplement_class('given_name')])).
ml_word('alien', noun, forms(['alien', 'aliens']), demand([dataset(7)])).
ml_word('alien', verb, forms(['alien', 'aliened', 'aliening', 'aliens']), demand([dataset(7)])).
ml_word('alien', adjective, forms(['alien']), demand([dataset(7)])).
ml_word('alike', adjective, forms(['alike']), demand([question_corpus(24)])).
ml_word('alike', adverb, forms(['alike']), demand([question_corpus(24)])).
ml_word('alisha', given_name, forms(['alisha']), demand([dataset(7), supplement_class('given_name')])).
ml_word('allergic', adjective, forms(['allergic']), demand([dataset(4), supplement_class('adjective')])).
ml_word('alligator', noun, forms(['alligator', 'alligators']), demand([dataset(13)])).
ml_word('allow', verb, forms(['allow', 'allowed', 'allowing', 'allows']), demand([question_corpus(5), dataset(15)])).
ml_word('allowance', noun, forms(['allowance', 'allowances']), demand([dataset(8)])).
ml_word('allowance', verb, forms(['allowance', 'allowanced', 'allowances', 'allowancing']), demand([dataset(8)])).
ml_word('alma', noun, forms(['alma', 'almas']), demand([dataset(11)])).
ml_word('almond', noun, forms(['almond', 'almonds']), demand([dataset(53)])).
ml_word('almost', adverb, forms(['almost']), demand([question_corpus(1), dataset(2)])).
ml_word('aloe', noun, forms(['aloe', 'aloes']), demand([dataset(5)])).
ml_word('alone', adjective, forms(['alone']), demand([dataset(4)])).
ml_word('alone', adverb, forms(['alone']), demand([dataset(4)])).
ml_word('along', adverb, forms(['along']), demand([dataset(10)])).
ml_word('along', preposition, forms(['along']), demand([dataset(10)])).
ml_word('already', adverb, forms(['already']), demand([question_corpus(5), dataset(83)])).
ml_word('also', adverb, forms(['also']), demand([question_corpus(1), dataset(227)])).
ml_word('also', conjunction, forms(['also']), demand([question_corpus(1), dataset(227)])).
ml_word('alter', verb, forms(['alter', 'altered', 'altering', 'alters']), demand([question_corpus(1)])).
ml_word('alternate', verb, forms(['alternate', 'alternated', 'alternates', 'alternating']), demand([dataset(4)])).
ml_word('altogether', adverb, forms(['altogether']), demand([question_corpus(3), dataset(64)])).
ml_word('aluminum', noun, forms(['aluminum', 'aluminums']), demand([dataset(14)])).
ml_word('always', adverb, forms(['always']), demand([question_corpus(5), dataset(24)])).
ml_word('am', verb, forms(['am', 'been', 'being', 'is', 'was']), demand([question_corpus(2), dataset(5)])).
ml_word('amalie', given_name, forms(['amalie']), demand([dataset(18), supplement_class('given_name')])).
ml_word('amanda', given_name, forms(['amanda']), demand([dataset(11), supplement_class('given_name')])).
ml_word('amaya', given_name, forms(['amaya']), demand([dataset(24), supplement_class('given_name')])).
ml_word('amber', noun, forms(['amber', 'ambers']), demand([dataset(4)])).
ml_word('amber', verb, forms(['amber', 'ambered', 'ambering', 'ambers']), demand([dataset(4)])).
ml_word('amber', adjective, forms(['amber']), demand([dataset(4)])).
ml_word('ambulance', noun, forms(['ambulance', 'ambulances']), demand([dataset(6)])).
ml_word('america', place_name, forms(['america']), demand([dataset(34), supplement_class('place_name')])).
ml_word('among', preposition, forms(['among']), demand([dataset(19)])).
ml_word('amongst', preposition, forms(['amongst']), demand([dataset(5)])).
ml_word('amount', noun, forms(['amount', 'amounts']), demand([question_corpus(17), dataset(405)])).
ml_word('amount', verb, forms(['amount', 'amounted', 'amounting', 'amounts']), demand([question_corpus(17), dataset(407)])).
ml_word('amoura', given_name, forms(['amoura']), demand([dataset(10), supplement_class('given_name')])).
ml_word('amuse', verb, forms(['amuse', 'amused', 'amuses', 'amusing']), demand([dataset(4)])).
ml_word('amused', adjective, forms(['amused']), demand([dataset(4)])).
ml_word('amusement', noun, forms(['amusement', 'amusements']), demand([dataset(20)])).
ml_word('amy', noun, forms(['amies', 'amy']), demand([dataset(14)])).
ml_word('anaconda', noun, forms(['anaconda', 'anacondas']), demand([dataset(4)])).
ml_word('analytics', noun, forms(['analytics', 'analyticses']), demand([dataset(4)])).
ml_word('analyze', verb, forms(['analyze', 'analyzed', 'analyzes', 'analyzing']), demand([question_corpus(1)])).
ml_word('anchor', noun, forms(['anchor', 'anchors']), demand([dataset(8)])).
ml_word('anchor', verb, forms(['anchor', 'anchored', 'anchoring', 'anchors']), demand([dataset(8)])).
ml_word('andre', given_name, forms(['andre']), demand([question_corpus(8), supplement_class('given_name')])).
ml_word('andrew', given_name, forms(['andrew']), demand([dataset(17), supplement_class('given_name')])).
ml_word('andy', given_name, forms(['andy']), demand([dataset(24), supplement_class('given_name')])).
ml_word('angle', noun, forms(['angle', 'angles']), demand([question_corpus(21), dataset(40), questioning_paper_lexicon])).
ml_word('angle', verb, forms(['angle', 'angled', 'angles', 'angling']), demand([question_corpus(21), dataset(40), questioning_paper_lexicon])).
ml_word('angles', noun, forms(['angles']), demand([question_corpus(10), dataset(10)])).
ml_word('animal', noun, forms(['animal', 'animals']), demand([question_corpus(6), dataset(35)])).
ml_word('animal', adjective, forms(['animal']), demand([question_corpus(3)])).
ml_word('ankle', noun, forms(['ankle', 'ankles']), demand([dataset(4)])).
ml_word('ann', noun, forms(['ann', 'anns']), demand([dataset(10)])).
ml_word('anna', noun, forms(['anna', 'annas']), demand([dataset(20)])).
ml_word('annie', given_name, forms(['annie']), demand([dataset(10), supplement_class('given_name')])).
ml_word('anniversary', noun, forms(['anniversaries', 'anniversary']), demand([dataset(7)])).
ml_word('anniversary', adjective, forms(['anniversary']), demand([dataset(7)])).
ml_word('announce', verb, forms(['announce', 'announced', 'announces', 'announcing']), demand([dataset(4)])).
ml_word('announcement', noun, forms(['announcement', 'announcements']), demand([dataset(4)])).
ml_word('annual', noun, forms(['annual', 'annuals']), demand([dataset(26)])).
ml_word('annual', adjective, forms(['annual']), demand([dataset(26)])).
ml_word('another', adjective, forms(['another']), demand([question_corpus(46), dataset(162)])).
ml_word('another', pronoun, forms(['another']), demand([question_corpus(46), dataset(162)])).
ml_word('answer', noun, forms(['answer', 'answers']), demand([question_corpus(43), dataset(19)])).
ml_word('answer', verb, forms(['answer', 'answered', 'answering', 'answers']), demand([question_corpus(44), dataset(19)])).
ml_word('anticipate', verb, forms(['anticipate', 'anticipated', 'anticipates', 'anticipating']), demand([question_corpus(1)])).
ml_word('antilogarithm', noun, forms(['antilogarithm', 'antilogarithms']), demand([webster_domain('math')])).
ml_word('antiparallels', noun, forms(['antiparallels']), demand([webster_domain('geom')])).
ml_word('antique', noun, forms(['antique', 'antiques']), demand([dataset(10)])).
ml_word('antique', adjective, forms(['antique']), demand([dataset(10)])).
ml_word('antonio', given_name, forms(['antonio']), demand([dataset(18), supplement_class('given_name')])).
ml_word('any', adjective, forms(['any']), demand([question_corpus(24), dataset(54)])).
ml_word('any', adverb, forms(['any']), demand([question_corpus(24), dataset(54)])).
ml_word('any', pronoun, forms(['any']), demand([question_corpus(24), dataset(54)])).
ml_word('anya', given_name, forms(['anya']), demand([dataset(12), supplement_class('given_name')])).
ml_word('anyone', noun, forms(['anyone', 'anyones']), demand([question_corpus(48)])).
ml_word('anything', noun, forms(['anything', 'anythings']), demand([question_corpus(57), dataset(4)])).
ml_word('anything', adverb, forms(['anything']), demand([question_corpus(57), dataset(4)])).
ml_word('apart', adverb, forms(['apart']), demand([question_corpus(3)])).
ml_word('apartment', noun, forms(['apartment', 'apartments']), demand([question_corpus(1), dataset(48)])).
ml_word('apiece', adverb, forms(['apiece']), demand([dataset(2)])).
ml_word('appear', noun, forms(['appear', 'appears']), demand([question_corpus(1)])).
ml_word('appear', verb, forms(['appear', 'appeared', 'appearing', 'appears']), demand([question_corpus(1)])).
ml_word('apple', noun, forms(['apple', 'apples']), demand([question_corpus(3), dataset(109)])).
ml_word('apple', verb, forms(['apple', 'appled', 'apples', 'appling']), demand([question_corpus(3), dataset(109)])).
ml_word('application', noun, forms(['application', 'applications']), demand([dataset(7)])).
ml_word('apply', verb, forms(['applied', 'applies', 'apply', 'applying']), demand([question_corpus(2), dataset(14)])).
ml_word('appointment', noun, forms(['appointment', 'appointments']), demand([dataset(6)])).
ml_word('approach', noun, forms(['approach', 'approaches']), demand([question_corpus(21)])).
ml_word('approach', verb, forms(['approach', 'approached', 'approaches', 'approaching']), demand([question_corpus(21)])).
ml_word('appropriate', noun, forms(['appropriate', 'appropriates']), demand([question_corpus(1)])).
ml_word('appropriate', verb, forms(['appropriate', 'appropriated', 'appropriates', 'appropriating']), demand([question_corpus(1)])).
ml_word('appropriate', adjective, forms(['appropriate']), demand([question_corpus(1)])).
ml_word('approve', verb, forms(['approve', 'approved', 'approves', 'approving']), demand([dataset(7)])).
ml_word('approximate', verb, forms(['approximate', 'approximated', 'approximates', 'approximating']), demand([question_corpus(1)])).
ml_word('approximate', adjective, forms(['approximate']), demand([question_corpus(1)])).
ml_word('approximately', adverb, forms(['approximately']), demand([dataset(4)])).
ml_word('april', noun, forms(['april', 'aprils']), demand([dataset(12)])).
ml_word('apsis', noun, forms(['apse', 'apsides', 'apsis', 'apsises', 'see']), demand([question_corpus(181), dataset(31)])).
ml_word('aquarium', noun, forms(['aquaria', 'aquarium', 'aquariums']), demand([question_corpus(1), dataset(89)])).
ml_word('arabella', given_name, forms(['arabella']), demand([dataset(15), supplement_class('given_name')])).
ml_word('arc', noun, forms(['arc', 'arcs']), demand([question_corpus(1)])).
ml_word('arcade', noun, forms(['arcade', 'arcades']), demand([dataset(17)])).
ml_word('archie', given_name, forms(['archie']), demand([dataset(3), supplement_class('given_name')])).
ml_word('area', noun, forms(['area', 'areas']), demand([question_corpus(42), dataset(88), questioning_paper_lexicon])).
ml_word('aren', given_name, forms(['aren']), demand([dataset(3), supplement_class('given_name')])).
ml_word('arena', noun, forms(['arena', 'arenas', 'arenæ']), demand([dataset(11)])).
ml_word('ariel', noun, forms(['ariel', 'ariels']), demand([dataset(6)])).
ml_word('arm', noun, forms(['arm', 'arms']), demand([dataset(2)])).
ml_word('arm', verb, forms(['arm', 'armed', 'arming', 'arms']), demand([dataset(2)])).
ml_word('arms', noun, forms(['arms']), demand([dataset(2)])).
ml_word('around', adverb, forms(['around']), demand([question_corpus(4), dataset(81)])).
ml_word('around', preposition, forms(['around']), demand([question_corpus(4), dataset(81)])).
ml_word('arrange', verb, forms(['arrange', 'arranged', 'arranges', 'arranging']), demand([question_corpus(2)])).
ml_word('arrangement', noun, forms(['arrangement', 'arrangements']), demand([question_corpus(2)])).
ml_word('array', noun, forms(['array', 'arrays']), demand([question_corpus(6), questioning_paper_lexicon])).
ml_word('array', verb, forms(['array', 'arrayed', 'arraying', 'arrays']), demand([question_corpus(6), questioning_paper_lexicon])).
ml_word('arrive', noun, forms(['arrive', 'arrives']), demand([question_corpus(1), dataset(8)])).
ml_word('arrive', verb, forms(['arrive', 'arrived', 'arrives', 'arriving']), demand([question_corpus(1), dataset(18)])).
ml_word('art', noun, forms(['art', 'arts']), demand([question_corpus(4), dataset(13)])).
ml_word('artemis', given_name, forms(['artemis']), demand([dataset(9), supplement_class('given_name')])).
ml_word('artistic', adjective, forms(['artistic']), demand([dataset(3)])).
ml_word('artwork', noun, forms(['artwork', 'artworks']), demand([dataset(12), supplement_class('common_noun')])).
ml_word('arvin', given_name, forms(['arvin']), demand([dataset(5), supplement_class('given_name')])).
ml_word('ash', noun, forms(['ash', 'ashes']), demand([dataset(2)])).
ml_word('ash', verb, forms(['ash', 'ashed', 'ashes', 'ashing']), demand([dataset(2)])).
ml_word('ashes', noun, forms(['ashes']), demand([dataset(2)])).
ml_word('ashley', given_name, forms(['ashley']), demand([dataset(14), supplement_class('given_name')])).
ml_word('aside', noun, forms(['aside', 'asides']), demand([dataset(6)])).
ml_word('aside', adverb, forms(['aside']), demand([dataset(6)])).
ml_word('ask', noun, forms(['ask', 'asks']), demand([question_corpus(23), dataset(20)])).
ml_word('ask', verb, forms(['ask', 'asked', 'asking', 'asks']), demand([question_corpus(34), dataset(42)])).
ml_word('asking', noun, forms(['asking', 'askings']), demand([question_corpus(2), dataset(14)])).
ml_word('asleep', adjective, forms(['asleep']), demand([dataset(2)])).
ml_word('asleep', adverb, forms(['asleep']), demand([dataset(2)])).
ml_word('aspect', noun, forms(['aspect', 'aspects']), demand([question_corpus(1)])).
ml_word('aspect', verb, forms(['aspect', 'aspected', 'aspecting', 'aspects']), demand([question_corpus(1)])).
ml_word('aspire', noun, forms(['aspire', 'aspires']), demand([dataset(2)])).
ml_word('aspire', verb, forms(['aspire', 'aspired', 'aspires', 'aspiring']), demand([dataset(2)])).
ml_word('assess', verb, forms(['assess', 'assessed', 'assesses', 'assessing']), demand([question_corpus(1)])).
ml_word('assign', verb, forms(['assign', 'assigned', 'assigning', 'assigns']), demand([dataset(3)])).
ml_word('assignment', noun, forms(['assignment', 'assignments']), demand([question_corpus(1), dataset(4)])).
ml_word('associate', verb, forms(['associate', 'associated', 'associates', 'associating']), demand([question_corpus(4)])).
ml_word('associated', adjective, forms(['associated']), demand([question_corpus(4)])).
ml_word('association', noun, forms(['association', 'associations']), demand([question_corpus(2), questioning_paper_lexicon])).
ml_word('associative', adjective, forms(['associative']), demand([question_corpus(1), questioning_paper_lexicon])).
ml_word('assume', verb, forms(['assume', 'assumed', 'assumes', 'assuming']), demand([dataset(36)])).
ml_word('assuming', adjective, forms(['assuming']), demand([dataset(24)])).
ml_word('assumption', noun, forms(['assumption', 'assumptions']), demand([question_corpus(3)])).
ml_word('ate', noun, forms(['ate', 'ates']), demand([dataset(40)])).
ml_word('athlete', noun, forms(['athlete', 'athletes']), demand([question_corpus(1), dataset(2)])).
ml_word('attend', verb, forms(['attend', 'attended', 'attending', 'attends']), demand([question_corpus(1), dataset(15)])).
ml_word('attendance', noun, forms(['attendance', 'attendances']), demand([dataset(4)])).
ml_word('attention', noun, forms(['attention', 'attentions']), demand([question_corpus(7)])).
ml_word('attribute', noun, forms(['attribute', 'attributes']), demand([question_corpus(4)])).
ml_word('attribute', verb, forms(['attribute', 'attributed', 'attributes', 'attributing']), demand([question_corpus(4)])).
ml_word('aubree', given_name, forms(['aubree']), demand([dataset(3), supplement_class('given_name')])).
ml_word('auction', noun, forms(['auction', 'auctions']), demand([dataset(10)])).
ml_word('auction', verb, forms(['auction', 'auctioned', 'auctioning', 'auctions']), demand([dataset(10)])).
ml_word('audience', noun, forms(['audience', 'audiences']), demand([dataset(4)])).
ml_word('auditorium', noun, forms(['auditorium', 'auditoriums']), demand([dataset(10)])).
ml_word('austin', adjective, forms(['austin']), demand([dataset(16)])).
ml_word('ava', noun, forms(['ava', 'avas']), demand([dataset(4)])).
ml_word('available', adjective, forms(['available']), demand([dataset(18)])).
ml_word('average', noun, forms(['average', 'averages']), demand([dataset(200)])).
ml_word('average', verb, forms(['average', 'averaged', 'averages', 'averaging']), demand([dataset(205)])).
ml_word('average', adjective, forms(['average']), demand([dataset(200)])).
ml_word('avianna', given_name, forms(['avianna']), demand([dataset(14), supplement_class('given_name')])).
ml_word('avoid', verb, forms(['avoid', 'avoided', 'avoiding', 'avoids']), demand([question_corpus(1), dataset(2)])).
ml_word('award', noun, forms(['award', 'awards']), demand([dataset(2)])).
ml_word('award', verb, forms(['award', 'awarded', 'awarding', 'awards']), demand([dataset(2)])).
ml_word('aware', adjective, forms(['aware']), demand([dataset(2)])).
ml_word('away', adverb, forms(['away']), demand([question_corpus(4), dataset(120)])).
ml_word('ax', verb, forms(['ax', 'axed', 'axes', 'axing']), demand([question_corpus(1)])).
ml_word('axe', noun, forms(['axe', 'axes']), demand([question_corpus(1)])).
ml_word('axis', noun, forms(['axes', 'axis', 'axises']), demand([question_corpus(7)])).
ml_word('aziz', given_name, forms(['aziz']), demand([dataset(22), supplement_class('given_name')])).
ml_word('b', algebra_symbol, forms(['b']), demand([question_corpus(12), dataset(47), supplement_class('algebra_symbol')])).
ml_word('baby', noun, forms(['babies', 'baby']), demand([dataset(11)])).
ml_word('baby', verb, forms(['babied', 'babies', 'baby', 'babying']), demand([dataset(11)])).
ml_word('baby', adjective, forms(['baby']), demand([dataset(11)])).
ml_word('babysit', verb, forms(['babysat', 'babysit', 'babysits', 'babysitting']), demand([question_corpus(1), dataset(6), supplement_class('corpus_verb')])).
ml_word('babysitter', noun, forms(['babysitter', 'babysitters']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('back', noun, forms(['back', 'backs']), demand([question_corpus(5), dataset(112)])).
ml_word('back', verb, forms(['back', 'backed', 'backing', 'backs']), demand([question_corpus(5), dataset(112)])).
ml_word('back', adjective, forms(['back']), demand([question_corpus(5), dataset(112)])).
ml_word('back', adverb, forms(['back']), demand([question_corpus(5), dataset(112)])).
ml_word('backward', noun, forms(['backward', 'backwards']), demand([question_corpus(2), dataset(16)])).
ml_word('backward', verb, forms(['backward', 'backwarded', 'backwarding', 'backwards']), demand([question_corpus(2), dataset(16)])).
ml_word('backward', adjective, forms(['backward']), demand([question_corpus(2), dataset(1)])).
ml_word('backward', adverb, forms(['backward']), demand([question_corpus(2), dataset(1)])).
ml_word('backwards', adverb, forms(['backwards']), demand([dataset(15)])).
ml_word('backyard', noun, forms(['backyard', 'backyards']), demand([dataset(15), supplement_class('common_noun')])).
ml_word('bacon', noun, forms(['bacon', 'bacons']), demand([dataset(10)])).
ml_word('bad', adjective, forms(['bad', 'worse', 'worst']), demand([dataset(11)])).
ml_word('badminton', noun, forms(['badminton', 'badmintons']), demand([dataset(2)])).
ml_word('bag', noun, forms(['bag', 'bags']), demand([question_corpus(2), dataset(117)])).
ml_word('bag', verb, forms(['bag', 'baged', 'bagged', 'bagging', 'baging', 'bags']), demand([question_corpus(2), dataset(117)])).
ml_word('baguette', noun, forms(['baguette', 'baguettes']), demand([dataset(4)])).
ml_word('bake', noun, forms(['bake', 'bakes']), demand([dataset(47)])).
ml_word('bake', verb, forms(['bake', 'baked', 'bakes', 'baking']), demand([question_corpus(2), dataset(54)])).
ml_word('baker', noun, forms(['baker', 'bakers']), demand([dataset(19)])).
ml_word('bakery', noun, forms(['bakeries', 'bakery']), demand([dataset(30)])).
ml_word('baking', noun, forms(['baking', 'bakings']), demand([dataset(6)])).
ml_word('balance', noun, forms(['balance', 'balances']), demand([question_corpus(1), dataset(12)])).
ml_word('balance', verb, forms(['balance', 'balanced', 'balances', 'balancing']), demand([question_corpus(2), dataset(15)])).
ml_word('bale', noun, forms(['bale', 'bales']), demand([dataset(19)])).
ml_word('bale', verb, forms(['bale', 'baled', 'bales', 'baling']), demand([dataset(19)])).
ml_word('bali', place_name, forms(['bali']), demand([dataset(8), supplement_class('place_name')])).
ml_word('ball', noun, forms(['ball', 'balls']), demand([question_corpus(1), dataset(165)])).
ml_word('ball', verb, forms(['ball', 'balled', 'balling', 'balls']), demand([question_corpus(1), dataset(165)])).
ml_word('balloon', noun, forms(['balloon', 'balloons']), demand([dataset(128)])).
ml_word('balloon', verb, forms(['balloon', 'ballooned', 'ballooning', 'balloons']), demand([dataset(128)])).
ml_word('bamboo', noun, forms(['bamboo', 'bamboos']), demand([dataset(11)])).
ml_word('bamboo', verb, forms(['bamboo', 'bambooed', 'bambooes', 'bambooing']), demand([dataset(11)])).
ml_word('banana', noun, forms(['banana', 'bananas']), demand([dataset(16)])).
ml_word('bank', noun, forms(['bank', 'banks']), demand([dataset(26)])).
ml_word('bank', verb, forms(['bank', 'banked', 'banking', 'banks']), demand([dataset(26)])).
ml_word('bar', noun, forms(['bar', 'bars']), demand([question_corpus(5), dataset(89)])).
ml_word('bar', verb, forms(['bar', 'barred', 'barring', 'bars']), demand([question_corpus(5), dataset(89)])).
ml_word('barbecue', noun, forms(['barbecue', 'barbecues']), demand([dataset(10)])).
ml_word('barbecue', verb, forms(['barbecue', 'barbecued', 'barbecues', 'barbecuing']), demand([dataset(10)])).
ml_word('bark', noun, forms(['bark', 'barks']), demand([dataset(22)])).
ml_word('bark', verb, forms(['bark', 'barked', 'barking', 'barks']), demand([dataset(48)])).
ml_word('barney', given_name, forms(['barney']), demand([dataset(8), supplement_class('given_name')])).
ml_word('barrel', noun, forms(['barrel', 'barrels']), demand([dataset(17)])).
ml_word('barrel', verb, forms(['barrel', 'barreled', 'barreling', 'barrels']), demand([dataset(17)])).
ml_word('barry', adjective, forms(['barry']), demand([dataset(7)])).
ml_word('base', noun, forms(['base', 'bases']), demand([question_corpus(12), dataset(11), questioning_paper_lexicon])).
ml_word('base', verb, forms(['base', 'based', 'bases', 'basing']), demand([question_corpus(21), dataset(15), questioning_paper_lexicon])).
ml_word('base', adjective, forms(['base']), demand([question_corpus(11), dataset(11), questioning_paper_lexicon])).
ml_word('baseball', noun, forms(['baseball', 'baseballs']), demand([dataset(25)])).
ml_word('based', adjective, forms(['based']), demand([question_corpus(9), dataset(4)])).
ml_word('basis', noun, forms(['bases', 'basis', 'basises']), demand([question_corpus(1)])).
ml_word('basket', noun, forms(['basket', 'baskets']), demand([dataset(61)])).
ml_word('basket', verb, forms(['basket', 'basketed', 'basketing', 'baskets']), demand([dataset(61)])).
ml_word('basketball', noun, forms(['basketball', 'basketballs']), demand([question_corpus(1), dataset(26), supplement_class('common_noun')])).
ml_word('batch', noun, forms(['batch', 'batches']), demand([question_corpus(2), dataset(69)])).
ml_word('bath', noun, forms(['bath', 'baths']), demand([dataset(17)])).
ml_word('bathe', verb, forms(['bathe', 'bathed', 'bathes', 'bathing']), demand([dataset(12)])).
ml_word('bathing', noun, forms(['bathing', 'bathings']), demand([dataset(12)])).
ml_word('bathroom', noun, forms(['bathroom', 'bathrooms']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('bathtub', noun, forms(['bathtub', 'bathtubs']), demand([dataset(12), supplement_class('common_noun')])).
ml_word('bathwater', noun, forms(['bathwater']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('batter', noun, forms(['batter', 'batters']), demand([dataset(8)])).
ml_word('batter', verb, forms(['batter', 'battered', 'battering', 'batters']), demand([dataset(8)])).
ml_word('battery', noun, forms(['batteries', 'battery']), demand([question_corpus(1)])).
ml_word('battle', noun, forms(['battle', 'battles']), demand([dataset(6)])).
ml_word('battle', verb, forms(['battle', 'battled', 'battles', 'battling']), demand([dataset(6)])).
ml_word('battle', adjective, forms(['battle']), demand([dataset(6)])).
ml_word('bay', noun, forms(['bay', 'bays']), demand([dataset(2)])).
ml_word('bay', verb, forms(['bay', 'bayed', 'baying', 'bays']), demand([dataset(2)])).
ml_word('bay', adjective, forms(['bay']), demand([dataset(2)])).
ml_word('beach', noun, forms(['beach', 'beaches']), demand([dataset(7)])).
ml_word('beach', verb, forms(['beach', 'beached', 'beaches', 'beaching']), demand([dataset(7)])).
ml_word('bead', noun, forms(['bead', 'beads']), demand([question_corpus(1)])).
ml_word('bead', verb, forms(['bead', 'beaded', 'beading', 'beads']), demand([question_corpus(1)])).
ml_word('bean', noun, forms(['bean', 'beans']), demand([question_corpus(2), dataset(16)])).
ml_word('bear', noun, forms(['bear', 'bears']), demand([question_corpus(1), dataset(35)])).
ml_word('bear', verb, forms(['bear', 'beared', 'bearing', 'bears', 'bore', 'born']), demand([question_corpus(2), dataset(75)])).
ml_word('beat', noun, forms(['beat', 'beats']), demand([dataset(9)])).
ml_word('beat', verb, forms(['beat', 'beated', 'beating', 'beats']), demand([dataset(9)])).
ml_word('beat', adjective, forms(['beat']), demand([dataset(9)])).
ml_word('beau', noun, forms(['beau', 'beaus', 'beaux', 'f']), demand([dataset(12)])).
ml_word('beaver', noun, forms(['beaver', 'beavers']), demand([dataset(7)])).
ml_word('because', conjunction, forms(['because']), demand([question_corpus(3), dataset(349)])).
ml_word('beckett', given_name, forms(['beckett']), demand([dataset(6), supplement_class('given_name')])).
ml_word('becky', given_name, forms(['becky']), demand([dataset(4), supplement_class('given_name')])).
ml_word('become', verb, forms(['became', 'become', 'becomes', 'becoming']), demand([question_corpus(1), dataset(33)])).
ml_word('bed', noun, forms(['bed', 'beds']), demand([dataset(27)])).
ml_word('bed', verb, forms(['bed', 'bedded', 'bedding', 'beded', 'beding', 'beds']), demand([dataset(27)])).
ml_word('bedbug', noun, forms(['bedbug', 'bedbugs']), demand([dataset(40)])).
ml_word('bedroom', noun, forms(['bedroom', 'bedrooms']), demand([question_corpus(1), dataset(44)])).
ml_word('bedtime', noun, forms(['bedtime', 'bedtimes']), demand([dataset(4)])).
ml_word('beef', noun, forms(['beef', 'beeves']), demand([dataset(27)])).
ml_word('beef', adjective, forms(['beef']), demand([dataset(27)])).
ml_word('beeswax', noun, forms(['beeswax', 'beeswaxes']), demand([dataset(30)])).
ml_word('before', adverb, forms(['before']), demand([question_corpus(13), dataset(250)])).
ml_word('before', preposition, forms(['before']), demand([question_corpus(13), dataset(250)])).
ml_word('begin', noun, forms(['begin', 'begins']), demand([question_corpus(2), dataset(14)])).
ml_word('begin', verb, forms(['began', 'begin', 'begined', 'begining', 'beginning', 'begins', 'begun']), demand([question_corpus(4), dataset(54), supplement_class('corpus_verb')])).
ml_word('beginning', noun, forms(['beginning', 'beginnings']), demand([question_corpus(1), dataset(36)])).
ml_word('behind', noun, forms(['behind', 'behinds']), demand([question_corpus(2), dataset(8)])).
ml_word('behind', adverb, forms(['behind']), demand([question_corpus(2), dataset(8)])).
ml_word('behind', preposition, forms(['behind']), demand([question_corpus(2), dataset(8)])).
ml_word('belief', noun, forms(['belief', 'beliefs']), demand([question_corpus(1)])).
ml_word('believe', verb, forms(['believe', 'believed', 'believes', 'believing']), demand([question_corpus(1)])).
ml_word('bella', given_name, forms(['bella']), demand([dataset(4), supplement_class('given_name')])).
ml_word('belong', verb, forms(['belong', 'belonged', 'belonging', 'belongs']), demand([question_corpus(1), dataset(1)])).
ml_word('below', adverb, forms(['below']), demand([question_corpus(2), dataset(23)])).
ml_word('below', preposition, forms(['below']), demand([question_corpus(2), dataset(23)])).
ml_word('ben', noun, forms(['ben', 'bens']), demand([dataset(11)])).
ml_word('ben', adverb, forms(['ben']), demand([dataset(11)])).
ml_word('ben', preposition, forms(['ben']), demand([dataset(11)])).
ml_word('beneath', adverb, forms(['beneath']), demand([dataset(2)])).
ml_word('beneath', preposition, forms(['beneath']), demand([dataset(2)])).
ml_word('benefit', noun, forms(['benefit', 'benefits']), demand([question_corpus(3)])).
ml_word('benefit', verb, forms(['benefit', 'benefited', 'benefiting', 'benefits', 'benefitting']), demand([question_corpus(3)])).
ml_word('berry', noun, forms(['berries', 'berry']), demand([dataset(6)])).
ml_word('berry', verb, forms(['berried', 'berries', 'berry', 'berrying']), demand([dataset(6)])).
ml_word('bert', given_name, forms(['bert']), demand([dataset(18), supplement_class('given_name')])).
ml_word('beside', adverb, forms(['beside']), demand([dataset(4)])).
ml_word('beside', preposition, forms(['beside']), demand([dataset(4)])).
ml_word('best', noun, forms(['best', 'bests']), demand([question_corpus(7)])).
ml_word('best', verb, forms(['best', 'bested', 'besting', 'bests']), demand([question_corpus(7)])).
ml_word('best', adjective, forms(['best']), demand([question_corpus(7)])).
ml_word('best', adverb, forms(['best']), demand([question_corpus(7)])).
ml_word('bet', noun, forms(['bet', 'bets']), demand([dataset(4)])).
ml_word('bet', verb, forms(['bet', 'bets', 'betting']), demand([dataset(4)])).
ml_word('bet', adjective, forms(['bet']), demand([dataset(4)])).
ml_word('bet', adverb, forms(['bet']), demand([dataset(4)])).
ml_word('beth', given_name, forms(['beth']), demand([dataset(12), supplement_class('given_name')])).
ml_word('better', noun, forms(['better', 'betters']), demand([question_corpus(10), dataset(20)])).
ml_word('better', verb, forms(['better', 'bettered', 'bettering', 'betters']), demand([question_corpus(10), dataset(20)])).
ml_word('better', adjective, forms(['better']), demand([question_corpus(10), dataset(20)])).
ml_word('better', adverb, forms(['better']), demand([question_corpus(10), dataset(20)])).
ml_word('betty', noun, forms(['betties', 'betty']), demand([dataset(56)])).
ml_word('between', noun, forms(['between', 'betweens']), demand([question_corpus(47), dataset(139)])).
ml_word('between', preposition, forms(['between']), demand([question_corpus(47), dataset(139)])).
ml_word('bicycle', noun, forms(['bicycle', 'bicycles']), demand([dataset(68)])).
ml_word('bid', noun, forms(['bid', 'bids']), demand([dataset(115)])).
ml_word('bid', verb, forms(['bade', 'bid', 'bidden', 'bidding', 'bided', 'biding', 'bids']), demand([dataset(130)])).
ml_word('bidding', noun, forms(['bidding', 'biddings']), demand([dataset(15)])).
ml_word('big', noun, forms(['big', 'bigs']), demand([dataset(97)])).
ml_word('big', verb, forms(['big', 'biged', 'biging', 'bigs']), demand([dataset(97)])).
ml_word('big', adjective, forms(['big']), demand([dataset(97)])).
ml_word('bigger', adjective, forms(['bigger']), demand([question_corpus(2), dataset(6)])).
ml_word('biggest', adjective, forms(['biggest']), demand([dataset(4)])).
ml_word('bike', noun, forms(['bike', 'bikes']), demand([question_corpus(1), dataset(32)])).
ml_word('bike', verb, forms(['bike', 'biked', 'bikes', 'biking']), demand([question_corpus(1), dataset(32), supplement_class('corpus_verb')])).
ml_word('bill', noun, forms(['bill', 'bills']), demand([dataset(69)])).
ml_word('bill', verb, forms(['bill', 'billed', 'billing', 'bills']), demand([dataset(69)])).
ml_word('billie', given_name, forms(['billie']), demand([dataset(10), supplement_class('given_name')])).
ml_word('billy', noun, forms(['billies', 'billy']), demand([dataset(69)])).
ml_word('bin', noun, forms(['bin', 'bins']), demand([question_corpus(1), dataset(7)])).
ml_word('bin', verb, forms(['bin', 'binned', 'binning', 'bins']), demand([question_corpus(1), dataset(7)])).
ml_word('biquadratic', noun, forms(['biquadratic', 'biquadratics']), demand([webster_domain('math')])).
ml_word('biquadratic', adjective, forms(['biquadratic']), demand([webster_domain('math')])).
ml_word('bird', noun, forms(['bird', 'birds']), demand([question_corpus(2), dataset(36)])).
ml_word('bird', verb, forms(['bird', 'birded', 'birding', 'birds']), demand([question_corpus(2), dataset(36)])).
ml_word('birdhouse', noun, forms(['birdhouse', 'birdhouses']), demand([question_corpus(1), dataset(36), supplement_class('common_noun')])).
ml_word('birth', noun, forms(['birth', 'births']), demand([dataset(1)])).
ml_word('birthday', noun, forms(['birthday', 'birthdays']), demand([dataset(57)])).
ml_word('birthday', adjective, forms(['birthday']), demand([dataset(55)])).
ml_word('bisque', noun, forms(['bisque', 'bisques']), demand([dataset(2)])).
ml_word('bit', noun, forms(['bit', 'bits']), demand([dataset(2)])).
ml_word('bit', verb, forms(['bit', 'bits', 'bitted', 'bitting']), demand([dataset(2)])).
ml_word('bite', noun, forms(['bite', 'bites']), demand([dataset(15)])).
ml_word('bite', verb, forms(['bit', 'bite', 'bited', 'bites', 'biting', 'bitten']), demand([dataset(26)])).
ml_word('bitten', adjective, forms(['bitten']), demand([dataset(9)])).
ml_word('black', noun, forms(['black', 'blacks']), demand([dataset(67)])).
ml_word('black', verb, forms(['black', 'blacked', 'blacking', 'blacks']), demand([dataset(67)])).
ml_word('black', adjective, forms(['black']), demand([dataset(67)])).
ml_word('black', adverb, forms(['black']), demand([dataset(67)])).
ml_word('blake', given_name, forms(['blake']), demand([dataset(12), supplement_class('given_name')])).
ml_word('blank', noun, forms(['blank', 'blanks']), demand([question_corpus(2)])).
ml_word('blank', verb, forms(['blank', 'blanked', 'blanking', 'blanks']), demand([question_corpus(2)])).
ml_word('blender', noun, forms(['blender', 'blenders']), demand([dataset(4)])).
ml_word('block', noun, forms(['block', 'blocks']), demand([question_corpus(17), dataset(94)])).
ml_word('block', verb, forms(['block', 'blocked', 'blocking', 'blocks']), demand([question_corpus(17), dataset(94)])).
ml_word('bloom', noun, forms(['bloom', 'blooms']), demand([dataset(8)])).
ml_word('bloom', verb, forms(['bloom', 'bloomed', 'blooming', 'blooms']), demand([dataset(8)])).
ml_word('blue', noun, forms(['blue', 'blues']), demand([question_corpus(4), dataset(102)])).
ml_word('blue', verb, forms(['blue', 'blued', 'blues', 'bluing']), demand([question_corpus(4), dataset(102)])).
ml_word('blue', adjective, forms(['blue', 'bluer', 'bluest']), demand([question_corpus(4), dataset(102)])).
ml_word('blueberry', noun, forms(['blueberries', 'blueberry']), demand([question_corpus(1), dataset(8)])).
ml_word('boa', noun, forms(['boa', 'boas']), demand([dataset(10)])).
ml_word('board', noun, forms(['board', 'boards']), demand([dataset(37)])).
ml_word('board', verb, forms(['board', 'boarded', 'boarding', 'boards']), demand([dataset(41)])).
ml_word('boarding', noun, forms(['boarding', 'boardings']), demand([dataset(4)])).
ml_word('boat', noun, forms(['boat', 'boats']), demand([dataset(9)])).
ml_word('boat', verb, forms(['boat', 'boated', 'boating', 'boats']), demand([dataset(9)])).
ml_word('bob', noun, forms(['bob', 'bobs']), demand([dataset(14)])).
ml_word('bob', verb, forms(['bob', 'bobbed', 'bobbing', 'bobed', 'bobing', 'bobs']), demand([dataset(14)])).
ml_word('bobby', noun, forms(['bobbies', 'bobby']), demand([dataset(25)])).
ml_word('body', noun, forms(['bodies', 'body']), demand([question_corpus(1), dataset(8)])).
ml_word('body', verb, forms(['bodied', 'bodies', 'body', 'bodying']), demand([question_corpus(1), dataset(8)])).
ml_word('boisjoli', given_name, forms(['boisjoli']), demand([dataset(3), supplement_class('given_name')])).
ml_word('bone', noun, forms(['bone', 'bones']), demand([dataset(34)])).
ml_word('bone', verb, forms(['bone', 'boned', 'bones', 'boning']), demand([dataset(34)])).
ml_word('book', noun, forms(['book', 'books']), demand([question_corpus(5), dataset(424)])).
ml_word('book', verb, forms(['book', 'booked', 'booking', 'books']), demand([question_corpus(5), dataset(424)])).
ml_word('bookshelf', noun, forms(['bookshelf', 'bookshelves']), demand([dataset(4)])).
ml_word('boot', noun, forms(['boot', 'boots']), demand([dataset(39)])).
ml_word('boot', verb, forms(['boot', 'booted', 'booting', 'boots']), demand([dataset(39)])).
ml_word('boots', noun, forms(['boots', 'bootses']), demand([dataset(39)])).
ml_word('bore', verb, forms(['bore', 'bored', 'bores', 'boring']), demand([dataset(8)])).
ml_word('boring', noun, forms(['boring', 'borings']), demand([dataset(8)])).
ml_word('born', adjective, forms(['born']), demand([question_corpus(1), dataset(40)])).
ml_word('borrow', noun, forms(['borrow', 'borrows']), demand([dataset(10)])).
ml_word('borrow', verb, forms(['borrow', 'borrowed', 'borrowing', 'borrows']), demand([dataset(41)])).
ml_word('both', adjective, forms(['both']), demand([question_corpus(32), dataset(215)])).
ml_word('both', conjunction, forms(['both']), demand([question_corpus(32), dataset(215)])).
ml_word('bottle', noun, forms(['bottle', 'bottles']), demand([dataset(152)])).
ml_word('bottle', verb, forms(['bottle', 'bottled', 'bottles', 'bottling']), demand([dataset(152)])).
ml_word('bottom', noun, forms(['bottom', 'bottoms']), demand([question_corpus(3), dataset(38)])).
ml_word('bottom', verb, forms(['bottom', 'bottomed', 'bottoming', 'bottoms']), demand([question_corpus(3), dataset(38)])).
ml_word('bottom', adjective, forms(['bottom']), demand([question_corpus(3), dataset(38)])).
ml_word('bought', noun, forms(['bought', 'boughts']), demand([dataset(316)])).
ml_word('bought', adjective, forms(['bought']), demand([dataset(316)])).
ml_word('bowl', noun, forms(['bowl', 'bowls']), demand([dataset(8)])).
ml_word('bowl', verb, forms(['bowl', 'bowled', 'bowling', 'bowls']), demand([dataset(8)])).
ml_word('box', noun, forms(['box', 'boxes']), demand([question_corpus(14), dataset(269)])).
ml_word('box', verb, forms(['box', 'boxed', 'boxes', 'boxing']), demand([question_corpus(14), dataset(269)])).
ml_word('boy', noun, forms(['boy', 'boys']), demand([question_corpus(1), dataset(54)])).
ml_word('boy', verb, forms(['boy', 'boyed', 'boying', 'boys']), demand([question_corpus(1), dataset(54)])).
ml_word('boyfriend', noun, forms(['boyfriend', 'boyfriends']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('bracelet', noun, forms(['bracelet', 'bracelets']), demand([question_corpus(2), dataset(5)])).
ml_word('brad', noun, forms(['brad', 'brads']), demand([dataset(14)])).
ml_word('brain', noun, forms(['brain', 'brains']), demand([question_corpus(1)])).
ml_word('brain', verb, forms(['brain', 'brained', 'braining', 'brains']), demand([question_corpus(1)])).
ml_word('brand', noun, forms(['brand', 'brands']), demand([dataset(4)])).
ml_word('brandon', given_name, forms(['brandon']), demand([dataset(5), supplement_class('given_name')])).
ml_word('bread', noun, forms(['bread', 'breads']), demand([dataset(72)])).
ml_word('bread', verb, forms(['bread', 'breaded', 'breading', 'breads']), demand([dataset(72)])).
ml_word('break', noun, forms(['break', 'breaks']), demand([question_corpus(2), dataset(23)])).
ml_word('break', verb, forms(['break', 'breaking', 'breaks', 'broke', 'broken']), demand([question_corpus(3), dataset(25)])).
ml_word('breakfast', noun, forms(['breakfast', 'breakfasts']), demand([dataset(58)])).
ml_word('breakfast', verb, forms(['breakfast', 'breakfasted', 'breakfasting', 'breakfasts']), demand([dataset(58)])).
ml_word('breast', noun, forms(['breast', 'breasts']), demand([dataset(6)])).
ml_word('breast', verb, forms(['breast', 'breasted', 'breasting', 'breasts']), demand([dataset(6)])).
ml_word('bren', verb, forms(['bren', 'brenning', 'brens', 'brent']), demand([dataset(6)])).
ml_word('brenne', verb, forms(['brenne', 'brennes', 'brenning', 'brent']), demand([dataset(6)])).
ml_word('brent', noun, forms(['brent', 'brents']), demand([dataset(6)])).
ml_word('brent', adjective, forms(['brent']), demand([dataset(6)])).
ml_word('brew', noun, forms(['brew', 'brews']), demand([dataset(10)])).
ml_word('brew', verb, forms(['brew', 'brewed', 'brewing', 'brews']), demand([dataset(15)])).
ml_word('brian', given_name, forms(['brian']), demand([dataset(36), supplement_class('given_name')])).
ml_word('brianna', given_name, forms(['brianna']), demand([dataset(8), supplement_class('given_name')])).
ml_word('brick', noun, forms(['brick', 'bricks']), demand([question_corpus(2), dataset(28)])).
ml_word('brick', verb, forms(['brick', 'bricked', 'bricking', 'bricks']), demand([question_corpus(2), dataset(28)])).
ml_word('bride', noun, forms(['bride', 'brides']), demand([dataset(8)])).
ml_word('bride', verb, forms(['bride', 'brided', 'brides', 'briding']), demand([dataset(8)])).
ml_word('bridesmaid', noun, forms(['bridesmaid', 'bridesmaids']), demand([dataset(5)])).
ml_word('bridge', noun, forms(['bridge', 'bridges']), demand([dataset(24)])).
ml_word('bridge', verb, forms(['bridge', 'bridged', 'bridges', 'bridging']), demand([dataset(24)])).
ml_word('brie', noun, forms(['brie', 'bries']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('briefly', adverb, forms(['briefly']), demand([question_corpus(1)])).
ml_word('brim', noun, forms(['brim', 'brims']), demand([dataset(5)])).
ml_word('brim', verb, forms(['brim', 'brimed', 'briming', 'brimmed', 'brimming', 'brims']), demand([dataset(5)])).
ml_word('brim', adjective, forms(['brim']), demand([dataset(5)])).
ml_word('bring', verb, forms(['bring', 'bringing', 'brings', 'brought']), demand([dataset(86)])).
ml_word('brinley', given_name, forms(['brinley']), demand([dataset(27), supplement_class('given_name')])).
ml_word('broadcast', noun, forms(['broadcast', 'broadcasts']), demand([dataset(4)])).
ml_word('broke', verb, forms(['broke', 'broked', 'brokes', 'broking']), demand([dataset(2)])).
ml_word('broker', noun, forms(['broker', 'brokers']), demand([dataset(10)])).
ml_word('bronco', noun, forms(['bronco', 'broncos']), demand([dataset(4)])).
ml_word('bronner', family_name, forms(['bronner']), demand([dataset(7), supplement_class('family_name')])).
ml_word('broomstick', noun, forms(['broomstick', 'broomsticks']), demand([dataset(3)])).
ml_word('brother', noun, forms(['brethren', 'brother', 'brothers', 'see']), demand([question_corpus(181), dataset(185)])).
ml_word('brother', verb, forms(['brother', 'brothered', 'brothering', 'brothers']), demand([dataset(154)])).
ml_word('brown', noun, forms(['brown', 'browns']), demand([dataset(25)])).
ml_word('brown', verb, forms(['brown', 'browned', 'browning', 'browns']), demand([dataset(25)])).
ml_word('brown', adjective, forms(['brown', 'browner', 'brownest']), demand([dataset(25)])).
ml_word('brownie', noun, forms(['brownie', 'brownies']), demand([dataset(24)])).
ml_word('bryan', given_name, forms(['bryan']), demand([dataset(8), supplement_class('given_name')])).
ml_word('bubba', given_name, forms(['bubba']), demand([dataset(2), supplement_class('given_name')])).
ml_word('bubble', noun, forms(['bubble', 'bubbles']), demand([dataset(12)])).
ml_word('bubble', verb, forms(['bubble', 'bubbled', 'bubbles', 'bubbling']), demand([dataset(12)])).
ml_word('bucket', noun, forms(['bucket', 'buckets']), demand([dataset(52)])).
ml_word('budget', noun, forms(['budget', 'budgets']), demand([dataset(63)])).
ml_word('budget', verb, forms(['budget', 'budgeted', 'budgeting', 'budgets']), demand([dataset(81), supplement_class('corpus_verb')])).
ml_word('buffet', noun, forms(['buffet', 'buffets']), demand([dataset(21)])).
ml_word('buffet', verb, forms(['buffet', 'buffeted', 'buffeting', 'buffets']), demand([dataset(21)])).
ml_word('bug', noun, forms(['bug', 'bugs']), demand([question_corpus(2)])).
ml_word('build', noun, forms(['build', 'builds']), demand([question_corpus(3), dataset(22)])).
ml_word('build', verb, forms(['build', 'builded', 'building', 'builds', 'built']), demand([question_corpus(5), dataset(69)])).
ml_word('builder', noun, forms(['builder', 'builders']), demand([dataset(9)])).
ml_word('building', noun, forms(['building', 'buildings']), demand([question_corpus(1), dataset(35)])).
ml_word('built', noun, forms(['built', 'builts']), demand([question_corpus(1), dataset(12)])).
ml_word('built', adjective, forms(['built']), demand([question_corpus(1), dataset(12)])).
ml_word('bun', noun, forms(['bun', 'buns']), demand([dataset(6)])).
ml_word('bunny', noun, forms(['bunnies', 'bunny']), demand([dataset(12)])).
ml_word('bureau', noun, forms(['bureau', 'bureaus', 'bureaux', 'f']), demand([dataset(12)])).
ml_word('burn', noun, forms(['burn', 'burns']), demand([question_corpus(1), dataset(12)])).
ml_word('burn', verb, forms(['burn', 'burned', 'burning', 'burns']), demand([question_corpus(1), dataset(22)])).
ml_word('burned', adjective, forms(['burned']), demand([dataset(10)])).
ml_word('burrow', verb, forms(['burrow', 'burrowed', 'burrowing', 'burrows']), demand([dataset(4)])).
ml_word('burst', noun, forms(['burst', 'bursts']), demand([dataset(2)])).
ml_word('burst', verb, forms(['burst', 'bursted', 'bursting', 'bursts']), demand([dataset(2)])).
ml_word('bury', noun, forms(['buries', 'bury']), demand([dataset(8)])).
ml_word('bury', verb, forms(['buried', 'buries', 'bury', 'burying']), demand([dataset(14)])).
ml_word('bus', noun, forms(['bus', 'buses']), demand([question_corpus(1), dataset(40)])).
ml_word('bush', noun, forms(['bush', 'bushes']), demand([dataset(17)])).
ml_word('bush', verb, forms(['bush', 'bushed', 'bushes', 'bushing']), demand([dataset(17)])).
ml_word('business', noun, forms(['business', 'businesses']), demand([dataset(29)])).
ml_word('busy', verb, forms(['busied', 'busies', 'busy', 'busying']), demand([dataset(8)])).
ml_word('busy', adjective, forms(['busy']), demand([dataset(8)])).
ml_word('butcher', noun, forms(['butcher', 'butchers']), demand([dataset(2)])).
ml_word('butcher', verb, forms(['butcher', 'butchered', 'butchering', 'butchers']), demand([dataset(2)])).
ml_word('butter', noun, forms(['butter', 'butters']), demand([dataset(85)])).
ml_word('butter', verb, forms(['butter', 'buttered', 'buttering', 'butters']), demand([dataset(85)])).
ml_word('button', noun, forms(['button', 'buttons']), demand([question_corpus(1), dataset(28)])).
ml_word('button', verb, forms(['button', 'buttoned', 'buttoning', 'buttons']), demand([question_corpus(1), dataset(28)])).
ml_word('buttons', noun, forms(['buttons', 'buttonses']), demand([question_corpus(1), dataset(24)])).
ml_word('buy', verb, forms(['bought', 'buy', 'buying', 'buys']), demand([question_corpus(3), dataset(781)])).
ml_word('c', algebra_symbol, forms(['c']), demand([question_corpus(14), dataset(35), supplement_class('algebra_symbol')])).
ml_word('c2', math_notation, forms(['c2']), demand([question_corpus(1), supplement_class('math_notation')])).
ml_word('cabinet', noun, forms(['cabinet', 'cabinets']), demand([question_corpus(2), dataset(2)])).
ml_word('cabinet', verb, forms(['cabinet', 'cabineted', 'cabineting', 'cabinets']), demand([question_corpus(2), dataset(2)])).
ml_word('cabinet', adjective, forms(['cabinet']), demand([question_corpus(2), dataset(2)])).
ml_word('cable', noun, forms(['cable', 'cables']), demand([dataset(2)])).
ml_word('cable', verb, forms(['cable', 'cabled', 'cables', 'cabling']), demand([dataset(2)])).
ml_word('cafe', noun, forms(['cafe', 'cafes']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('cafeteria', noun, forms(['cafeteria', 'cafeterias']), demand([dataset(4)])).
ml_word('cake', noun, forms(['cake', 'cakes']), demand([dataset(82)])).
ml_word('cake', verb, forms(['cake', 'caked', 'cakes', 'caking']), demand([dataset(82)])).
ml_word('calculate', verb, forms(['calculate', 'calculated', 'calculater', 'calculates', 'calculating']), demand([question_corpus(10), dataset(64)])).
ml_word('calculated', adjective, forms(['calculated']), demand([question_corpus(3), dataset(2)])).
ml_word('calculating', noun, forms(['calculating', 'calculatings']), demand([question_corpus(4)])).
ml_word('calculating', adjective, forms(['calculating']), demand([question_corpus(4)])).
ml_word('calculation', noun, forms(['calculation', 'calculations']), demand([question_corpus(6), dataset(1)])).
ml_word('calculus', noun, forms(['calculi', 'calculus', 'calculuses']), demand([dataset(8)])).
ml_word('calf', noun, forms(['calf', 'calves']), demand([dataset(6)])).
ml_word('call', noun, forms(['call', 'calls']), demand([dataset(57)])).
ml_word('call', verb, forms(['call', 'called', 'calling', 'calls']), demand([question_corpus(3), dataset(69)])).
ml_word('calling', noun, forms(['calling', 'callings']), demand([dataset(9)])).
ml_word('calorie', noun, forms(['calorie', 'calories']), demand([dataset(57)])).
ml_word('calve', verb, forms(['calve', 'calved', 'calves', 'calving']), demand([dataset(6)])).
ml_word('came', noun, forms(['came', 'cames']), demand([question_corpus(3), dataset(35)])).
ml_word('camel', noun, forms(['camel', 'camels']), demand([dataset(7)])).
ml_word('cameron', given_name, forms(['cameron']), demand([dataset(10), supplement_class('given_name')])).
ml_word('camille', given_name, forms(['camille']), demand([dataset(4), supplement_class('given_name')])).
ml_word('camp', noun, forms(['camp', 'camps']), demand([dataset(44)])).
ml_word('camp', verb, forms(['camp', 'camped', 'camping', 'camps']), demand([dataset(46)])).
ml_word('camping', noun, forms(['camping', 'campings']), demand([dataset(2)])).
ml_word('can', noun, forms(['can', 'cans']), demand([dataset(52)])).
ml_word('can', verb, forms(['can', 'caned', 'caning', 'canned', 'canning', 'cans']), demand([dataset(52)])).
ml_word('candice', given_name, forms(['candice']), demand([dataset(21), supplement_class('given_name')])).
ml_word('candle', noun, forms(['candle', 'candles']), demand([question_corpus(1), dataset(262)])).
ml_word('candy', noun, forms(['candies', 'candy']), demand([dataset(123)])).
ml_word('candy', verb, forms(['candied', 'candies', 'candy', 'candying']), demand([dataset(123)])).
ml_word('cannoneer', noun, forms(['cannoneer', 'cannoneers']), demand([dataset(8)])).
ml_word('cannot', function_word, forms(['cannot']), demand([question_corpus(1), dataset(20), supplement_class('function_word')])).
ml_word('cap', noun, forms(['cap', 'caps']), demand([dataset(4)])).
ml_word('cap', verb, forms(['cap', 'caped', 'caping', 'capped', 'capping', 'caps']), demand([dataset(4)])).
ml_word('capable', adjective, forms(['capable']), demand([dataset(1)])).
ml_word('capacity', noun, forms(['capacities', 'capacity']), demand([dataset(23)])).
ml_word('cappuccino', noun, forms(['cappuccino', 'cappuccinos']), demand([dataset(3), supplement_class('common_noun')])).
ml_word('car', noun, forms(['car', 'cars']), demand([question_corpus(2), dataset(345)])).
ml_word('carbon', noun, forms(['carbon', 'carbons']), demand([dataset(4)])).
ml_word('card', noun, forms(['card', 'cards']), demand([question_corpus(7), dataset(145)])).
ml_word('card', verb, forms(['card', 'carded', 'carding', 'cards']), demand([question_corpus(7), dataset(145)])).
ml_word('cardboard', noun, forms(['cardboard', 'cardboards']), demand([question_corpus(1)])).
ml_word('care', noun, forms(['care', 'cares']), demand([question_corpus(1), dataset(4)])).
ml_word('care', verb, forms(['care', 'cared', 'cares', 'caring']), demand([question_corpus(1), dataset(4)])).
ml_word('carina', noun, forms(['carina', 'carinas']), demand([dataset(2)])).
ml_word('carl', noun, forms(['carl', 'carls']), demand([dataset(8)])).
ml_word('carla', given_name, forms(['carla']), demand([dataset(53), supplement_class('given_name')])).
ml_word('carlos', given_name, forms(['carlos']), demand([dataset(6), supplement_class('given_name')])).
ml_word('carly', given_name, forms(['carly']), demand([dataset(8), supplement_class('given_name')])).
ml_word('carman', noun, forms(['carman', 'carmen']), demand([dataset(50)])).
ml_word('carmela', given_name, forms(['carmela']), demand([dataset(4), supplement_class('given_name')])).
ml_word('carnival', noun, forms(['carnival', 'carnivals']), demand([question_corpus(2)])).
ml_word('carolyn', given_name, forms(['carolyn']), demand([dataset(4), supplement_class('given_name')])).
ml_word('carriage', noun, forms(['carriage', 'carriages']), demand([dataset(4)])).
ml_word('carrot', noun, forms(['carrot', 'carrots']), demand([dataset(22)])).
ml_word('carry', noun, forms(['carries', 'carry']), demand([question_corpus(1), dataset(31)])).
ml_word('carry', verb, forms(['carried', 'carries', 'carry', 'carrying']), demand([question_corpus(1), dataset(66)])).
ml_word('carrying', noun, forms(['carrying', 'carryings']), demand([dataset(6)])).
ml_word('carsharing', noun, forms(['carsharing', 'carsharings']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('cart', noun, forms(['cart', 'carts']), demand([dataset(6)])).
ml_word('cart', verb, forms(['cart', 'carted', 'carting', 'carts']), demand([dataset(6)])).
ml_word('carter', noun, forms(['carter', 'carters']), demand([dataset(5)])).
ml_word('carton', noun, forms(['carton', 'cartons']), demand([question_corpus(1), dataset(32)])).
ml_word('cary', given_name, forms(['cary']), demand([dataset(24), supplement_class('given_name')])).
ml_word('case', noun, forms(['case', 'cases']), demand([question_corpus(1), dataset(15)])).
ml_word('case', verb, forms(['case', 'cased', 'cases', 'casing']), demand([question_corpus(1), dataset(15)])).
ml_word('cash', noun, forms(['cash', 'cashes']), demand([dataset(19)])).
ml_word('cash', verb, forms(['cash', 'cashed', 'cashes', 'cashing', 'casing']), demand([dataset(20)])).
ml_word('cashier', noun, forms(['cashier', 'cashiers']), demand([dataset(15)])).
ml_word('cashier', verb, forms(['cahiered', 'cashier', 'cashiering', 'cashiers']), demand([dataset(15)])).
ml_word('cask', noun, forms(['cask', 'casks']), demand([dataset(6)])).
ml_word('cask', verb, forms(['cask', 'casked', 'casking', 'casks']), demand([dataset(6)])).
ml_word('cat', noun, forms(['cat', 'cats']), demand([question_corpus(4), dataset(84)])).
ml_word('cat', verb, forms(['cat', 'cats', 'catted', 'catting']), demand([question_corpus(4), dataset(84)])).
ml_word('catch', noun, forms(['catch', 'catches']), demand([dataset(71)])).
ml_word('catch', verb, forms(['catch', 'catched', 'catches', 'catching', 'caught']), demand([dataset(123)])).
ml_word('catching', noun, forms(['catching', 'catchings']), demand([dataset(1)])).
ml_word('category', noun, forms(['categories', 'category']), demand([question_corpus(6)])).
ml_word('caterer', noun, forms(['caterer', 'caterers']), demand([dataset(16)])).
ml_word('catherine', given_name, forms(['catherine']), demand([dataset(4), supplement_class('given_name')])).
ml_word('cathy', given_name, forms(['cathy']), demand([dataset(24), supplement_class('given_name')])).
ml_word('cattle', noun, forms(['cattle']), demand([dataset(15)])).
ml_word('cauldron', noun, forms(['cauldron', 'cauldrons']), demand([dataset(3), supplement_class('common_noun')])).
ml_word('cause', noun, forms(['cause', 'causes']), demand([dataset(13)])).
ml_word('cause', verb, forms(['cause', 'caused', 'causes', 'causing']), demand([dataset(16)])).
ml_word('cause', conjunction, forms(['cause']), demand([dataset(12)])).
ml_word('cave', noun, forms(['cave', 'caves']), demand([dataset(5)])).
ml_word('cave', verb, forms(['cave', 'caved', 'caves', 'caving']), demand([dataset(5)])).
ml_word('cds', abbreviation, forms(['cds']), demand([dataset(24), supplement_class('abbreviation')])).
ml_word('cecil', given_name, forms(['cecil']), demand([dataset(10), supplement_class('given_name')])).
ml_word('ceil', verb, forms(['ceil', 'ceiled', 'ceiling', 'ceils']), demand([dataset(26)])).
ml_word('ceiling', noun, forms(['ceiling', 'ceilings']), demand([dataset(26)])).
ml_word('celebrate', verb, forms(['celebrate', 'celebrated', 'celebrates', 'celebrating']), demand([question_corpus(1), dataset(12)])).
ml_word('celebrated', adjective, forms(['celebrated']), demand([dataset(5)])).
ml_word('celebration', noun, forms(['celebration', 'celebrations']), demand([question_corpus(2), dataset(4)])).
ml_word('celebrity', noun, forms(['celebriries', 'celebrities', 'celebrity']), demand([dataset(4)])).
ml_word('celine', given_name, forms(['celine']), demand([dataset(8), supplement_class('given_name')])).
ml_word('cell', noun, forms(['cell', 'cells']), demand([question_corpus(2), dataset(10)])).
ml_word('cell', verb, forms(['cell', 'celled', 'celling', 'cells']), demand([question_corpus(2), dataset(10)])).
ml_word('cent', noun, forms(['cent', 'cents']), demand([question_corpus(1), dataset(84)])).
ml_word('center', noun, forms(['center', 'centers']), demand([question_corpus(13), dataset(6)])).
ml_word('centimeter', noun, forms(['centimeter', 'centimeters']), demand([question_corpus(7), dataset(46)])).
ml_word('ceriph', noun, forms(['ceriph', 'type']), demand([question_corpus(1), dataset(20)])).
ml_word('certain', noun, forms(['certain', 'certains']), demand([question_corpus(2), dataset(12)])).
ml_word('certain', adjective, forms(['certain']), demand([question_corpus(2), dataset(12)])).
ml_word('certain', adverb, forms(['certain']), demand([question_corpus(2), dataset(12)])).
ml_word('certificate', noun, forms(['certificate', 'certificates']), demand([dataset(2)])).
ml_word('certificate', verb, forms(['certificate', 'certificated', 'certificates', 'certificating']), demand([dataset(2)])).
ml_word('certification', noun, forms(['certification', 'certifications']), demand([dataset(5)])).
ml_word('chair', noun, forms(['chair', 'chairs']), demand([dataset(26)])).
ml_word('chair', verb, forms(['chair', 'chaired', 'chairing', 'chairs']), demand([dataset(26)])).
ml_word('challenge', noun, forms(['challenge', 'challenges']), demand([question_corpus(1)])).
ml_word('challenge', verb, forms(['challenge', 'challenged', 'challenges', 'challenging']), demand([question_corpus(5)])).
ml_word('champagne', noun, forms(['champagne', 'champagnes']), demand([dataset(24)])).
ml_word('chance', noun, forms(['chance', 'chances']), demand([dataset(13)])).
ml_word('chance', verb, forms(['chance', 'chanced', 'chances', 'chancing']), demand([dataset(13)])).
ml_word('chance', adjective, forms(['chance']), demand([dataset(6)])).
ml_word('chance', adverb, forms(['chance']), demand([dataset(6)])).
ml_word('chandler', noun, forms(['chandler', 'chandlers']), demand([dataset(12)])).
ml_word('change', noun, forms(['change', 'changes']), demand([question_corpus(22), dataset(58)])).
ml_word('change', verb, forms(['change', 'changed', 'changes', 'changing']), demand([question_corpus(30), dataset(58)])).
ml_word('channel', noun, forms(['channel', 'channels']), demand([dataset(13)])).
ml_word('channel', verb, forms(['channel', 'channeled', 'channeling', 'channels']), demand([dataset(13)])).
ml_word('chapter', noun, forms(['chapter', 'chapters']), demand([dataset(22)])).
ml_word('chapter', verb, forms(['chapter', 'chaptered', 'chaptering', 'chapters']), demand([dataset(22)])).
ml_word('character', noun, forms(['character', 'characters']), demand([dataset(24)])).
ml_word('character', verb, forms(['character', 'charactered', 'charactering', 'characters']), demand([dataset(24)])).
ml_word('characteristic', noun, forms(['characteristic', 'characteristics']), demand([question_corpus(1)])).
ml_word('charge', noun, forms(['charge', 'charges']), demand([dataset(73)])).
ml_word('charge', verb, forms(['charge', 'charged', 'charges', 'charging']), demand([dataset(112)])).
ml_word('charity', noun, forms(['charities', 'charity']), demand([dataset(6)])).
ml_word('charles', given_name, forms(['charles']), demand([dataset(3), supplement_class('given_name')])).
ml_word('charlie', noun, forms(['charlie', 'charlies']), demand([dataset(15)])).
ml_word('chart', noun, forms(['chart', 'charts']), demand([question_corpus(2)])).
ml_word('chart', verb, forms(['chart', 'charted', 'charting', 'charts']), demand([question_corpus(2)])).
ml_word('chase', noun, forms(['chase', 'chases']), demand([dataset(8)])).
ml_word('chase', verb, forms(['chase', 'chased', 'chases', 'chasing']), demand([dataset(8)])).
ml_word('cheaper', adjective, forms(['cheaper']), demand([dataset(21), supplement_class('adjective')])).
ml_word('check', noun, forms(['check', 'checks']), demand([question_corpus(4), dataset(8)])).
ml_word('check', verb, forms(['check', 'checked', 'checking', 'checks']), demand([question_corpus(4), dataset(18)])).
ml_word('check', adjective, forms(['check']), demand([question_corpus(4), dataset(4)])).
ml_word('checker', verb, forms(['checker', 'checkered', 'checkering', 'checkers']), demand([dataset(14)])).
ml_word('checkered', adjective, forms(['checkered']), demand([dataset(14)])).
ml_word('cheese', noun, forms(['cheese', 'cheeses']), demand([dataset(113)])).
ml_word('cheesecake', noun, forms(['cheesecake', 'cheesecakes']), demand([dataset(20), supplement_class('common_noun')])).
ml_word('chef', noun, forms(['chef', 'chefs']), demand([dataset(10)])).
ml_word('cherry', noun, forms(['cherries', 'cherry']), demand([dataset(58)])).
ml_word('cherry', adjective, forms(['cherry']), demand([dataset(22)])).
ml_word('chess', noun, forms(['chess', 'chesses']), demand([dataset(10)])).
ml_word('chester', given_name, forms(['chester']), demand([dataset(6), supplement_class('given_name')])).
ml_word('chicken', noun, forms(['chicken', 'chickens']), demand([question_corpus(1), dataset(201)])).
ml_word('child', noun, forms(['child', 'children', 'childs']), demand([question_corpus(2), dataset(141)])).
ml_word('child', verb, forms(['child', 'childed', 'childing', 'childs']), demand([dataset(18)])).
ml_word('children', noun, forms(['children', 'childrens']), demand([question_corpus(2), dataset(123)])).
ml_word('chip', noun, forms(['chip', 'chips']), demand([dataset(94)])).
ml_word('chip', verb, forms(['chip', 'chiped', 'chiping', 'chipped', 'chipping', 'chips']), demand([dataset(94)])).
ml_word('chipmunk', noun, forms(['chipmunk', 'chipmunks']), demand([dataset(7)])).
ml_word('chips', noun, forms(['chips', 'chipses']), demand([dataset(76)])).
ml_word('chloe', given_name, forms(['chloe']), demand([dataset(20), supplement_class('given_name')])).
ml_word('chocolate', noun, forms(['chocolate', 'chocolates']), demand([dataset(163)])).
ml_word('choi', family_name, forms(['choi']), demand([dataset(8), supplement_class('family_name')])).
ml_word('choice', noun, forms(['choice', 'choices']), demand([dataset(6)])).
ml_word('choice', adjective, forms(['choice', 'choicer', 'choicest']), demand([dataset(6)])).
ml_word('choir', noun, forms(['choir', 'choirs']), demand([dataset(61)])).
ml_word('choose', verb, forms(['choose', 'choosed', 'chooses', 'choosing', 'chose', 'chosen']), demand([question_corpus(28), dataset(16)])).
ml_word('chop', noun, forms(['chop', 'chops']), demand([dataset(5)])).
ml_word('chop', verb, forms(['chop', 'choped', 'choping', 'chopped', 'chopping', 'chops']), demand([dataset(9)])).
ml_word('chops', noun, forms(['chops']), demand([dataset(2)])).
ml_word('choral', noun, forms(['choral', 'chorals']), demand([question_corpus(2)])).
ml_word('choral', adjective, forms(['choral']), demand([question_corpus(2)])).
ml_word('chore', noun, forms(['chore', 'chores']), demand([dataset(4)])).
ml_word('chore', verb, forms(['chore', 'chored', 'chores', 'choring']), demand([dataset(4)])).
ml_word('chose', noun, forms(['chose', 'choses']), demand([question_corpus(8), dataset(8)])).
ml_word('chosen', noun, forms(['chosen', 'chosens']), demand([question_corpus(1)])).
ml_word('chris', given_name, forms(['chris']), demand([dataset(26), supplement_class('given_name')])).
ml_word('christina', given_name, forms(['christina']), demand([dataset(7), supplement_class('given_name')])).
ml_word('christmas', noun, forms(['christmas', 'christmases']), demand([dataset(15)])).
ml_word('cilia', noun, forms(['cilia']), demand([dataset(2)])).
ml_word('cindy', given_name, forms(['cindy']), demand([dataset(5), supplement_class('given_name')])).
ml_word('circle', noun, forms(['circle', 'circles']), demand([question_corpus(10), dataset(5)])).
ml_word('circle', verb, forms(['circle', 'circled', 'circles', 'circling']), demand([question_corpus(11), dataset(5)])).
ml_word('circled', adjective, forms(['circled']), demand([question_corpus(1)])).
ml_word('circular', noun, forms(['circular', 'circulars']), demand([question_corpus(2)])).
ml_word('circular', adjective, forms(['circular']), demand([question_corpus(2)])).
ml_word('circulate', verb, forms(['circulate', 'circulated', 'circulates', 'circulating']), demand([question_corpus(1)])).
ml_word('circumcenter', noun, forms(['circumcenter', 'circumcenters']), demand([webster_domain('geom')])).
ml_word('circumference', noun, forms(['circumference', 'circumferences']), demand([question_corpus(2)])).
ml_word('circumference', verb, forms(['circumference', 'circumferenced', 'circumferences', 'circumferencing']), demand([question_corpus(2)])).
ml_word('citizen', noun, forms(['citizen', 'citizens']), demand([dataset(4)])).
ml_word('citizen', adjective, forms(['citizen']), demand([dataset(4)])).
ml_word('city', noun, forms(['cities', 'city']), demand([question_corpus(2), dataset(8), supplement_class('common_noun')])).
ml_word('city', adjective, forms(['city']), demand([question_corpus(2), dataset(6)])).
ml_word('claire', noun, forms(['claire', 'claires']), demand([dataset(14)])).
ml_word('clare', noun, forms(['clare', 'clares']), demand([question_corpus(3)])).
ml_word('class', noun, forms(['class', 'classes']), demand([question_corpus(21), dataset(243)])).
ml_word('class', verb, forms(['class', 'classed', 'classes', 'classing']), demand([question_corpus(21), dataset(243)])).
ml_word('classical', adjective, forms(['classical']), demand([dataset(8)])).
ml_word('classis', noun, forms(['classes', 'classis', 'classises']), demand([dataset(46)])).
ml_word('classmate', noun, forms(['classmate', 'classmates']), demand([question_corpus(4)])).
ml_word('classroom', noun, forms(['classroom', 'classrooms']), demand([question_corpus(3), dataset(38), supplement_class('common_noun')])).
ml_word('clay', noun, forms(['clay', 'clays']), demand([question_corpus(1)])).
ml_word('clay', verb, forms(['clay', 'clayed', 'claying', 'clays']), demand([question_corpus(1)])).
ml_word('clean', verb, forms(['clean', 'cleaned', 'cleaning', 'cleans']), demand([dataset(62)])).
ml_word('clean', adjective, forms(['clean', 'cleaner', 'cleanest']), demand([dataset(30)])).
ml_word('clean', adverb, forms(['clean']), demand([dataset(30)])).
ml_word('cleaner', noun, forms(['cleaner', 'cleaners']), demand([dataset(72)])).
ml_word('cleaning', noun, forms(['cleaning', 'cleanings']), demand([dataset(32)])).
ml_word('clear', noun, forms(['clear', 'clears']), demand([question_corpus(6), dataset(3)])).
ml_word('clear', verb, forms(['clear', 'cleared', 'clearing', 'clears']), demand([question_corpus(6), dataset(8)])).
ml_word('clear', adjective, forms(['clear', 'clearer', 'clearest']), demand([question_corpus(7), dataset(3)])).
ml_word('clear', adverb, forms(['clear']), demand([question_corpus(6), dataset(3)])).
ml_word('clearance', noun, forms(['clearance', 'clearances']), demand([dataset(4)])).
ml_word('clearer', noun, forms(['clearer', 'clearers']), demand([question_corpus(1)])).
ml_word('clearing', noun, forms(['clearing', 'clearings']), demand([dataset(2)])).
ml_word('clerk', noun, forms(['clerk', 'clerks']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('cliff', noun, forms(['cliff', 'cliffs', 'mus']), demand([dataset(12)])).
ml_word('climb', noun, forms(['climb', 'climbs']), demand([dataset(1)])).
ml_word('climb', verb, forms(['climb', 'climbed', 'climbing', 'climbs']), demand([dataset(1)])).
ml_word('clinic', noun, forms(['clinic', 'clinics']), demand([dataset(5)])).
ml_word('clinic', adjective, forms(['clinic']), demand([dataset(5)])).
ml_word('clip', noun, forms(['clip', 'clips']), demand([question_corpus(1)])).
ml_word('clip', verb, forms(['clip', 'cliped', 'cliping', 'clipped', 'clipping', 'clips']), demand([question_corpus(1)])).
ml_word('cloak', verb, forms(['cloak', 'cloaked', 'cloaking', 'cloaks']), demand([dataset(10)])).
ml_word('clock', noun, forms(['clock', 'clocks']), demand([question_corpus(3)])).
ml_word('clock', verb, forms(['clock', 'clocked', 'clocking', 'clocks']), demand([question_corpus(3)])).
ml_word('close', noun, forms(['close', 'closes']), demand([question_corpus(18), dataset(4)])).
ml_word('close', verb, forms(['close', 'closed', 'closes', 'closing']), demand([question_corpus(18), dataset(35)])).
ml_word('close', adjective, forms(['close', 'closer', 'closest']), demand([question_corpus(18), dataset(10)])).
ml_word('close', adverb, forms(['close']), demand([question_corpus(18), dataset(4)])).
ml_word('closer', noun, forms(['closer', 'closers']), demand([dataset(1)])).
ml_word('cloth', noun, forms(['cloth', 'cloths']), demand([dataset(9)])).
ml_word('clothe', verb, forms(['clothe', 'clothed', 'clothes', 'clothing']), demand([dataset(23)])).
ml_word('clothing', noun, forms(['clothing', 'clothings']), demand([dataset(17)])).
ml_word('cloudy', adjective, forms(['cloudy']), demand([question_corpus(1), supplement_class('adjective')])).
ml_word('club', noun, forms(['club', 'clubs']), demand([dataset(36)])).
ml_word('club', verb, forms(['club', 'clubbed', 'clubbing', 'clubed', 'clubing', 'clubs']), demand([dataset(36)])).
ml_word('clue', noun, forms(['clue', 'clues']), demand([question_corpus(3)])).
ml_word('cm', unit_abbreviation, forms(['cm']), demand([question_corpus(2), dataset(46), supplement_class('unit_abbreviation')])).
ml_word('coach', verb, forms(['coach', 'coached', 'coaches', 'coaching']), demand([dataset(10)])).
ml_word('coat', verb, forms(['coat', 'coated', 'coating', 'coats']), demand([dataset(12)])).
ml_word('cocoa', noun, forms(['cocoa', 'cocoas']), demand([dataset(6)])).
ml_word('coconut', noun, forms(['coconut', 'coconuts']), demand([dataset(32), supplement_class('common_noun')])).
ml_word('coefficient', noun, forms(['coefficient', 'coefficients']), demand([questioning_paper_lexicon])).
ml_word('coefficient', adjective, forms(['coefficient']), demand([questioning_paper_lexicon])).
ml_word('coffee', noun, forms(['coffee', 'coffees']), demand([dataset(85)])).
ml_word('coin', verb, forms(['coin', 'coined', 'coining', 'coins']), demand([question_corpus(4), dataset(72)])).
ml_word('coke', noun, forms(['coke', 'cokes']), demand([dataset(6)])).
ml_word('coke', verb, forms(['coke', 'coked', 'cokes', 'coking']), demand([dataset(6)])).
ml_word('cold', noun, forms(['cold', 'colds']), demand([dataset(10)])).
ml_word('cold', adjective, forms(['cold', 'colder', 'coldest']), demand([dataset(10)])).
ml_word('collect', noun, forms(['collect', 'collects']), demand([question_corpus(2), dataset(23)])).
ml_word('collect', verb, forms(['collect', 'collected', 'collecting', 'collects']), demand([question_corpus(2), dataset(76)])).
ml_word('collected', adjective, forms(['collected']), demand([dataset(40)])).
ml_word('collection', noun, forms(['collection', 'collections']), demand([question_corpus(3), dataset(69)])).
ml_word('collective', noun, forms(['collective', 'collectives']), demand([question_corpus(3)])).
ml_word('collective', adjective, forms(['collective']), demand([question_corpus(3)])).
ml_word('collectively', adverb, forms(['collectively']), demand([dataset(4)])).
ml_word('colleen', noun, forms(['colleen', 'colleens']), demand([dataset(9)])).
ml_word('colony', noun, forms(['colonies', 'colony']), demand([dataset(17)])).
ml_word('color', noun, forms(['color', 'colors']), demand([question_corpus(4), dataset(28)])).
ml_word('color', verb, forms(['color', 'colored', 'coloring', 'colors']), demand([question_corpus(5), dataset(47)])).
ml_word('colored', adjective, forms(['colored']), demand([dataset(19)])).
ml_word('coloring', noun, forms(['coloring', 'colorings']), demand([question_corpus(1)])).
ml_word('column', noun, forms(['column', 'columns']), demand([question_corpus(7), dataset(20)])).
ml_word('combination', noun, forms(['combination', 'combinations']), demand([question_corpus(1), dataset(1)])).
ml_word('combine', verb, forms(['combine', 'combined', 'combines', 'combining']), demand([question_corpus(2), dataset(68)])).
ml_word('combined', adjective, forms(['combined']), demand([dataset(54)])).
ml_word('combo', noun, forms(['combo', 'combos']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('comcast', named_entity, forms(['comcast']), demand([dataset(3), supplement_class('named_entity')])).
ml_word('come', noun, forms(['come', 'comes']), demand([question_corpus(8), dataset(57)])).
ml_word('come', verb, forms(['came', 'come', 'comes', 'coming']), demand([question_corpus(11), dataset(99)])).
ml_word('comes', noun, forms(['comes', 'comeses']), demand([question_corpus(6), dataset(27)])).
ml_word('comfortable', noun, forms(['comfortable', 'comfortables']), demand([question_corpus(2)])).
ml_word('comfortable', adjective, forms(['comfortable']), demand([question_corpus(2)])).
ml_word('comic', noun, forms(['comic', 'comics']), demand([dataset(13)])).
ml_word('comic', adjective, forms(['comic']), demand([dataset(13)])).
ml_word('coming', noun, forms(['coming', 'comings']), demand([dataset(7)])).
ml_word('coming', adjective, forms(['coming']), demand([dataset(7)])).
ml_word('commencement', noun, forms(['commencement', 'commencements']), demand([dataset(36)])).
ml_word('commission', noun, forms(['commission', 'commissions']), demand([dataset(12)])).
ml_word('commission', verb, forms(['commission', 'commissioned', 'commissioning', 'commissions']), demand([dataset(12)])).
ml_word('commit', verb, forms(['commit', 'commited', 'commiting', 'commits', 'committed', 'committing']), demand([dataset(2), supplement_class('corpus_verb')])).
ml_word('commitment', noun, forms(['commitment', 'commitments']), demand([dataset(1)])).
ml_word('committee', noun, forms(['committee', 'committees']), demand([dataset(7)])).
ml_word('common', noun, forms(['common', 'commons']), demand([question_corpus(47)])).
ml_word('common', verb, forms(['common', 'commoned', 'commoning', 'commons']), demand([question_corpus(47)])).
ml_word('common', adjective, forms(['common', 'commoner', 'commonest']), demand([question_corpus(47)])).
ml_word('communal', adjective, forms(['communal']), demand([dataset(2), supplement_class('adjective')])).
ml_word('communicate', verb, forms(['communicate', 'communicated', 'communicates', 'communicating']), demand([question_corpus(1)])).
ml_word('community', noun, forms(['communities', 'community']), demand([question_corpus(10), dataset(18)])).
ml_word('commutative', adjective, forms(['commutative']), demand([questioning_paper_lexicon])).
ml_word('commute', verb, forms(['commute', 'commuted', 'commutes', 'commuting']), demand([dataset(3)])).
ml_word('company', noun, forms(['companies', 'company']), demand([question_corpus(1), dataset(68)])).
ml_word('company', verb, forms(['companied', 'companies', 'company', 'companying']), demand([question_corpus(1), dataset(68)])).
ml_word('compare', noun, forms(['compare', 'compares']), demand([question_corpus(19)])).
ml_word('compare', verb, forms(['compare', 'compared', 'compares', 'comparing']), demand([question_corpus(24), dataset(15)])).
ml_word('comparison', verb, forms(['comparison', 'comparisoned', 'comparisoning', 'comparisons']), demand([question_corpus(2), dataset(6)])).
ml_word('compartment', noun, forms(['compartment', 'compartments']), demand([dataset(4)])).
ml_word('compensate', verb, forms(['compensate', 'compensated', 'compensates', 'compensating']), demand([dataset(1)])).
ml_word('competition', noun, forms(['competition', 'competitions']), demand([dataset(5)])).
ml_word('complaint', noun, forms(['complaint', 'complaints']), demand([dataset(5)])).
ml_word('complementary', noun, forms(['complementaries', 'complementary']), demand([question_corpus(1)])).
ml_word('complementary', adjective, forms(['complementary']), demand([question_corpus(1)])).
ml_word('complete', verb, forms(['complete', 'completed', 'completes', 'completing']), demand([question_corpus(1), dataset(63)])).
ml_word('complete', adjective, forms(['complete']), demand([question_corpus(1), dataset(55)])).
ml_word('completely', adverb, forms(['completely']), demand([question_corpus(1), dataset(10)])).
ml_word('complex', noun, forms(['complex', 'complexes']), demand([dataset(7)])).
ml_word('complex', adjective, forms(['complex']), demand([dataset(7)])).
ml_word('compliment', noun, forms(['compliment', 'compliments']), demand([dataset(5)])).
ml_word('compliment', verb, forms(['compliment', 'complimented', 'complimenting', 'compliments']), demand([dataset(5)])).
ml_word('compose', verb, forms(['compose', 'composed', 'composes', 'composing']), demand([question_corpus(3), dataset(40), questioning_paper_lexicon])).
ml_word('composed', adjective, forms(['composed']), demand([question_corpus(2), dataset(4)])).
ml_word('composition', noun, forms(['composition', 'compositions']), demand([dataset(6)])).
ml_word('compound', noun, forms(['compound', 'compounds']), demand([dataset(2)])).
ml_word('compound', verb, forms(['compound', 'compounded', 'compounding', 'compounds']), demand([dataset(2)])).
ml_word('compound', adjective, forms(['compound']), demand([dataset(2)])).
ml_word('computation', noun, forms(['computation', 'computations']), demand([question_corpus(1)])).
ml_word('compute', verb, forms(['compute', 'computed', 'computes', 'computing']), demand([dataset(1)])).
ml_word('computer', noun, forms(['computer', 'computers']), demand([question_corpus(1), dataset(35)])).
ml_word('concentrate', verb, forms(['concentrate', 'concentrated', 'concentrates', 'concentrating']), demand([dataset(4), supplement_class('corpus_verb')])).
ml_word('concentrated', adjective, forms(['concentrated']), demand([dataset(4), supplement_class('adjective')])).
ml_word('concession', noun, forms(['concession', 'concessions']), demand([dataset(6)])).
ml_word('conclude', verb, forms(['conclude', 'concluded', 'concludes', 'concluding']), demand([dataset(1)])).
ml_word('concrete', noun, forms(['concrete', 'concretes']), demand([dataset(17)])).
ml_word('concrete', verb, forms(['concrete', 'concreted', 'concretes', 'concreting']), demand([dataset(17)])).
ml_word('condition', noun, forms(['condition', 'conditions']), demand([question_corpus(1), dataset(6)])).
ml_word('condition', verb, forms(['condition', 'conditioned', 'conditioning', 'conditions']), demand([question_corpus(1), dataset(6)])).
ml_word('condominium', noun, forms(['condominium', 'condominiums']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('cone', noun, forms(['cone', 'cones']), demand([question_corpus(3), dataset(47)])).
ml_word('cone', verb, forms(['cone', 'coned', 'cones', 'coning']), demand([question_corpus(3), dataset(47)])).
ml_word('confusion', noun, forms(['confusion', 'confusions']), demand([question_corpus(1)])).
ml_word('congruent', adjective, forms(['congruent']), demand([questioning_paper_lexicon])).
ml_word('conic', noun, forms(['conic', 'conics']), demand([webster_domain('math')])).
ml_word('conic', adjective, forms(['conic']), demand([webster_domain('math')])).
ml_word('connect', verb, forms(['connect', 'connected', 'connecting', 'connects']), demand([question_corpus(6), dataset(11)])).
ml_word('connection', noun, forms(['connection', 'connections']), demand([question_corpus(13)])).
ml_word('connie', given_name, forms(['connie']), demand([dataset(22), supplement_class('given_name')])).
ml_word('consecutive', adjective, forms(['consecutive']), demand([question_corpus(1)])).
ml_word('conservation', noun, forms(['conservation', 'conservations']), demand([dataset(6)])).
ml_word('consider', verb, forms(['consider', 'considered', 'considering', 'considers']), demand([question_corpus(5), dataset(11)])).
ml_word('consist', verb, forms(['consist', 'consisted', 'consisting', 'consists']), demand([dataset(7)])).
ml_word('constant', noun, forms(['constant', 'constants']), demand([question_corpus(2)])).
ml_word('constant', adjective, forms(['constant']), demand([question_corpus(1)])).
ml_word('constantly', adverb, forms(['constantly']), demand([question_corpus(1)])).
ml_word('construct', verb, forms(['construct', 'constructed', 'constructing', 'constructs']), demand([dataset(2)])).
ml_word('construct', adjective, forms(['construct']), demand([dataset(2)])).
ml_word('construction', noun, forms(['construction', 'constructions']), demand([dataset(12)])).
ml_word('consume', verb, forms(['consume', 'consumed', 'consumes', 'consuming']), demand([dataset(41)])).
ml_word('consumption', noun, forms(['consumption', 'consumptions']), demand([dataset(2)])).
ml_word('contain', verb, forms(['contain', 'contained', 'containing', 'contains']), demand([dataset(83)])).
ml_word('container', noun, forms(['container', 'containers']), demand([question_corpus(5), dataset(29)])).
ml_word('content', noun, forms(['content', 'contents']), demand([dataset(1)])).
ml_word('content', verb, forms(['content', 'contented', 'contenting', 'contents']), demand([dataset(1)])).
ml_word('contest', noun, forms(['contest', 'contests']), demand([dataset(4)])).
ml_word('contest', verb, forms(['contest', 'contested', 'contesting', 'contests']), demand([dataset(4)])).
ml_word('context', noun, forms(['context', 'contexts']), demand([question_corpus(3), dataset(1)])).
ml_word('context', verb, forms(['context', 'contexted', 'contexting', 'contexts']), demand([question_corpus(3), dataset(1)])).
ml_word('context', adjective, forms(['context']), demand([question_corpus(3), dataset(1)])).
ml_word('continue', verb, forms(['continue', 'continued', 'continues', 'continuing']), demand([question_corpus(6), dataset(21)])).
ml_word('continued', adjective, forms(['continued']), demand([question_corpus(1), dataset(2)])).
ml_word('contract', noun, forms(['contract', 'contracts']), demand([dataset(8)])).
ml_word('contract', verb, forms(['contract', 'contracted', 'contracting', 'contracts']), demand([dataset(8)])).
ml_word('contract', adjective, forms(['contract']), demand([dataset(8)])).
ml_word('contribute', verb, forms(['contribute', 'contributed', 'contributes', 'contributing']), demand([question_corpus(2), dataset(18)])).
ml_word('contribution', noun, forms(['contribution', 'contributions']), demand([dataset(10)])).
ml_word('convenience', noun, forms(['convenience', 'conveniences']), demand([dataset(4)])).
ml_word('conversation', noun, forms(['conversation', 'conversations']), demand([question_corpus(1)])).
ml_word('convert', noun, forms(['convert', 'converts']), demand([dataset(18)])).
ml_word('convert', verb, forms(['convert', 'converted', 'converting', 'converts']), demand([dataset(25)])).
ml_word('cook', noun, forms(['cook', 'cooks']), demand([question_corpus(2), dataset(20)])).
ml_word('cook', verb, forms(['cook', 'cooked', 'cooking', 'cooks']), demand([question_corpus(2), dataset(64)])).
ml_word('cookfire', noun, forms(['cookfire', 'cookfires']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('cookie', noun, forms(['cookie', 'cookies']), demand([dataset(162)])).
ml_word('cookout', noun, forms(['cookout', 'cookouts']), demand([dataset(16), supplement_class('common_noun')])).
ml_word('cooky', noun, forms(['cookies', 'cooky']), demand([dataset(134)])).
ml_word('coop', noun, forms(['coop', 'coops']), demand([dataset(12)])).
ml_word('coop', verb, forms(['coop', 'cooped', 'cooping', 'coops']), demand([dataset(12)])).
ml_word('coordinate', noun, forms(['coordinate', 'coordinates']), demand([question_corpus(8), questioning_paper_lexicon, supplement_class('math_term')])).
ml_word('copy', noun, forms(['copies', 'copy']), demand([question_corpus(5), dataset(4)])).
ml_word('copy', verb, forms(['copied', 'copies', 'copy', 'copying']), demand([question_corpus(5), dataset(4)])).
ml_word('coral', noun, forms(['coral', 'corals']), demand([dataset(10)])).
ml_word('corey', given_name, forms(['corey']), demand([dataset(2), supplement_class('given_name')])).
ml_word('corn', noun, forms(['corn', 'corns']), demand([dataset(31)])).
ml_word('corn', verb, forms(['corn', 'corned', 'corning', 'corns']), demand([dataset(31)])).
ml_word('corner', verb, forms(['corner', 'cornered', 'cornering', 'corners']), demand([dataset(5)])).
ml_word('coronavirus', noun, forms(['coronavirus', 'coronaviruses']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('correct', verb, forms(['correct', 'corrected', 'correcting', 'corrects']), demand([question_corpus(4), dataset(2)])).
ml_word('correctly', adverb, forms(['correctly']), demand([question_corpus(2), supplement_class('adverb')])).
ml_word('correspond', verb, forms(['correspond', 'corresponded', 'corresponding', 'corresponds']), demand([question_corpus(2), supplement_class('corpus_verb')])).
ml_word('corresponding', adjective, forms(['corresponding']), demand([question_corpus(1)])).
ml_word('cost', noun, forms(['cost', 'costs']), demand([question_corpus(3), dataset(1057)])).
ml_word('cost', verb, forms(['cost', 'costing', 'costs']), demand([question_corpus(3), dataset(1063)])).
ml_word('cottage', noun, forms(['cottage', 'cottages']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('cotton', verb, forms(['cotton', 'cottoned', 'cottoning', 'cottons']), demand([dataset(5)])).
ml_word('count', noun, forms(['count', 'counts']), demand([question_corpus(28), dataset(26)])).
ml_word('count', verb, forms(['count', 'counted', 'counting', 'counts']), demand([question_corpus(51), dataset(49)])).
ml_word('counter', noun, forms(['counter', 'counters']), demand([question_corpus(15), dataset(4)])).
ml_word('counter', verb, forms(['counter', 'countered', 'countering', 'counters']), demand([question_corpus(15), dataset(4)])).
ml_word('counter', adjective, forms(['counter']), demand([dataset(4)])).
ml_word('counter', adverb, forms(['counter']), demand([dataset(4)])).
ml_word('counterexample', noun, forms(['counterexample', 'counterexamples']), demand([question_corpus(1), supplement_class('math_term')])).
ml_word('counterlath', noun, forms(['building', 'counterlath']), demand([question_corpus(1), dataset(35)])).
ml_word('country', noun, forms(['countries', 'country']), demand([dataset(15), supplement_class('common_noun')])).
ml_word('country', adjective, forms(['country']), demand([dataset(15)])).
ml_word('county', noun, forms(['counties', 'county']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('couple', verb, forms(['couple', 'coupled', 'couples', 'coupling']), demand([question_corpus(2), dataset(18)])).
ml_word('coupon', noun, forms(['coupon', 'coupons']), demand([question_corpus(1), dataset(30), supplement_class('common_noun')])).
ml_word('course', verb, forms(['course', 'coursed', 'courses', 'coursing']), demand([question_corpus(4), dataset(47)])).
ml_word('court', verb, forms(['court', 'courted', 'courting', 'courts']), demand([question_corpus(2)])).
ml_word('cousin', noun, forms(['cousin', 'cousins']), demand([dataset(14)])).
ml_word('cover', verb, forms(['cover', 'covered', 'covering', 'covers']), demand([question_corpus(7), dataset(64)])).
ml_word('covering', noun, forms(['covering', 'coverings']), demand([dataset(3)])).
ml_word('cow', noun, forms(['cow', 'cows']), demand([dataset(65)])).
ml_word('cow', verb, forms(['cow', 'cowed', 'cowing', 'cows']), demand([dataset(65)])).
ml_word('crab', verb, forms(['crab', 'crabed', 'crabing', 'crabs']), demand([dataset(22)])).
ml_word('crab', adjective, forms(['crab']), demand([dataset(22)])).
ml_word('crack', verb, forms(['crack', 'cracked', 'cracking', 'cracks']), demand([dataset(9)])).
ml_word('cracker', noun, forms(['cracker', 'crackers']), demand([dataset(10), supplement_class('common_noun')])).
ml_word('craft', verb, forms(['craft', 'crafted', 'crafting', 'crafts']), demand([question_corpus(1), dataset(19)])).
ml_word('crank', verb, forms(['crank', 'cranked', 'cranking', 'cranks']), demand([dataset(9)])).
ml_word('crate', verb, forms(['crate', 'crated', 'crates', 'crating']), demand([dataset(90)])).
ml_word('crawl', noun, forms(['crawl', 'crawls']), demand([dataset(2)])).
ml_word('crawl', verb, forms(['crawl', 'crawled', 'crawling', 'crawls']), demand([dataset(4), supplement_class('corpus_verb')])).
ml_word('crayon', verb, forms(['crayon', 'crayoned', 'crayoning', 'crayons']), demand([question_corpus(1)])).
ml_word('cream', verb, forms(['cream', 'creamed', 'creaming', 'creams']), demand([dataset(88)])).
ml_word('create', verb, forms(['create', 'created', 'creates', 'creating']), demand([question_corpus(7), dataset(20)])).
ml_word('credit', noun, forms(['credit', 'credits']), demand([dataset(5), supplement_class('common_noun')])).
ml_word('creep', verb, forms(['creep', 'creeping', 'creeps', 'crept']), demand([dataset(5)])).
ml_word('creeping', adjective, forms(['creeping']), demand([dataset(5)])).
ml_word('crew', noun, forms(['crew', 'crews']), demand([question_corpus(1), dataset(8), supplement_class('common_noun')])).
ml_word('cricket', noun, forms(['cricket', 'crickets']), demand([dataset(15)])).
ml_word('cricket', verb, forms(['cricket', 'cricketed', 'cricketing', 'crickets']), demand([dataset(15)])).
ml_word('croissant', noun, forms(['croissant', 'croissants']), demand([dataset(30), supplement_class('common_noun')])).
ml_word('crook', verb, forms(['crook', 'crooked', 'crooking', 'crooks']), demand([dataset(4)])).
ml_word('crop', verb, forms(['crop', 'croped', 'croping', 'cropped', 'cropping', 'crops']), demand([question_corpus(1)])).
ml_word('cross', verb, forms(['cross', 'crossed', 'crosses', 'crossing']), demand([question_corpus(2), dataset(6)])).
ml_word('cross', preposition, forms(['cross']), demand([question_corpus(2), dataset(6)])).
ml_word('crossword', noun, forms(['crossword', 'crosswords']), demand([dataset(7), supplement_class('common_noun')])).
ml_word('crowd', noun, forms(['crowd', 'crowds']), demand([dataset(12)])).
ml_word('crowd', verb, forms(['crowd', 'crowded', 'crowding', 'crowds']), demand([dataset(12)])).
ml_word('cub', noun, forms(['cub', 'cubs']), demand([dataset(9)])).
ml_word('cub', verb, forms(['cub', 'cubbed', 'cubbing', 'cubed', 'cubing', 'cubs']), demand([dataset(9)])).
ml_word('cube', verb, forms(['cube', 'cubed', 'cubes', 'cubing']), demand([question_corpus(18)])).
ml_word('cubic', noun, forms(['cubic', 'cubics']), demand([question_corpus(5), dataset(17), webster_domain('geom')])).
ml_word('cucumber', noun, forms(['cucumber', 'cucumbers']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('culture', verb, forms(['culture', 'cultured', 'cultures', 'culturing']), demand([question_corpus(1)])).
ml_word('cumulative', adjective, forms(['cumulative']), demand([dataset(1), supplement_class('adjective')])).
ml_word('cup', verb, forms(['cup', 'cupped', 'cupping', 'cups']), demand([question_corpus(8), dataset(386)])).
ml_word('cupcake', noun, forms(['cupcake', 'cupcakes']), demand([dataset(71), supplement_class('common_noun')])).
ml_word('curb', noun, forms(['curb', 'curbs']), demand([dataset(4)])).
ml_word('curb', verb, forms(['curb', 'curbed', 'curbing', 'curbs']), demand([dataset(4)])).
ml_word('current', noun, forms(['current', 'currents']), demand([dataset(71)])).
ml_word('currently', adverb, forms(['currently']), demand([question_corpus(1), dataset(99)])).
ml_word('curve', verb, forms(['curve', 'curved', 'curves', 'curving']), demand([question_corpus(1)])).
ml_word('customer', noun, forms(['customer', 'customers']), demand([question_corpus(1), dataset(172), supplement_class('common_noun')])).
ml_word('cut', noun, forms(['cut', 'cuts']), demand([question_corpus(2), dataset(110)])).
ml_word('cutting', adjective, forms(['cutting']), demand([dataset(25)])).
ml_word('cycle', noun, forms(['cycle', 'cycles']), demand([dataset(12), supplement_class('common_noun')])).
ml_word('cylinder', noun, forms(['cylinder', 'cylinders']), demand([question_corpus(10), dataset(3), supplement_class('math_term')])).
ml_word('cylindrical', adjective, forms(['cylindrical']), demand([dataset(11), supplement_class('adjective')])).
ml_word('cyrus', given_name, forms(['cyrus']), demand([dataset(8), supplement_class('given_name')])).
ml_word('d', algebra_symbol, forms(['d']), demand([question_corpus(8), dataset(14), supplement_class('algebra_symbol')])).
ml_word('d2', math_notation, forms(['d2']), demand([question_corpus(1), supplement_class('math_notation')])).
ml_word('dad', noun, forms(['dad', 'dads']), demand([dataset(30)])).
ml_word('daily', noun, forms(['dailies', 'daily']), demand([dataset(40)])).
ml_word('daily', adjective, forms(['daily']), demand([dataset(40)])).
ml_word('daily', adverb, forms(['daily']), demand([dataset(40)])).
ml_word('daisy', noun, forms(['daisies', 'daisy']), demand([dataset(24)])).
ml_word('dakota', given_name, forms(['dakota']), demand([dataset(19), supplement_class('given_name')])).
ml_word('dan', noun, forms(['dan', 'dans']), demand([dataset(5)])).
ml_word('danai', given_name, forms(['danai']), demand([dataset(11), supplement_class('given_name')])).
ml_word('dance', noun, forms(['dance', 'dances']), demand([dataset(12)])).
ml_word('dance', verb, forms(['dance', 'danced', 'dances', 'dancing']), demand([dataset(18)])).
ml_word('dancing', adjective, forms(['dancing']), demand([dataset(6)])).
ml_word('dandelion', noun, forms(['dandelion', 'dandelions']), demand([dataset(4)])).
ml_word('dangerous', adjective, forms(['dangerous']), demand([dataset(10)])).
ml_word('dani', given_name, forms(['dani']), demand([dataset(8), supplement_class('given_name')])).
ml_word('danielle', given_name, forms(['danielle']), demand([dataset(7), supplement_class('given_name')])).
ml_word('danny', given_name, forms(['danny']), demand([dataset(8), supplement_class('given_name')])).
ml_word('dara', given_name, forms(['dara']), demand([dataset(10), supplement_class('given_name')])).
ml_word('dark', noun, forms(['dark', 'darks']), demand([dataset(16)])).
ml_word('dark', verb, forms(['dark', 'darked', 'darking', 'darks']), demand([dataset(16)])).
ml_word('dark', adjective, forms(['dark']), demand([dataset(16)])).
ml_word('dart', noun, forms(['dart', 'darts']), demand([dataset(2)])).
ml_word('dart', verb, forms(['dart', 'darted', 'darting', 'darts']), demand([dataset(2)])).
ml_word('data', noun, forms(['data']), demand([question_corpus(19), dataset(16)])).
ml_word('datum', noun, forms(['data', 'datum', 'datums']), demand([question_corpus(19), dataset(16)])).
ml_word('daughter', noun, forms(['daughter', 'daughters', 'daughtren']), demand([dataset(41)])).
ml_word('david', given_name, forms(['david']), demand([dataset(24), supplement_class('given_name')])).
ml_word('davis', given_name, forms(['davis']), demand([dataset(12), supplement_class('given_name')])).
ml_word('dawn', noun, forms(['dawn', 'dawns']), demand([dataset(8)])).
ml_word('dawn', verb, forms(['dawn', 'dawned', 'dawning', 'dawns']), demand([dataset(8)])).
ml_word('day', noun, forms(['day', 'days']), demand([question_corpus(12), dataset(1189)])).
ml_word('daycare', noun, forms(['daycare', 'daycares']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('deadline', noun, forms(['deadline', 'deadlines']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('deal', noun, forms(['deal', 'deals']), demand([question_corpus(4), dataset(2)])).
ml_word('deal', verb, forms(['deal', 'dealing', 'deals', 'dealt']), demand([question_corpus(4), dataset(2)])).
ml_word('debra', given_name, forms(['debra']), demand([dataset(7), supplement_class('given_name')])).
ml_word('december', noun, forms(['december', 'decembers']), demand([dataset(8)])).
ml_word('decide', verb, forms(['decide', 'decided', 'decides', 'deciding']), demand([question_corpus(24), dataset(144)])).
ml_word('decided', adjective, forms(['decided']), demand([question_corpus(1), dataset(62)])).
ml_word('decimal', noun, forms(['decimal', 'decimals']), demand([dataset(25), questioning_paper_lexicon])).
ml_word('decimal', adjective, forms(['decimal']), demand([dataset(25), questioning_paper_lexicon])).
ml_word('decision', noun, forms(['decision', 'decisions']), demand([question_corpus(3)])).
ml_word('deck', noun, forms(['deck', 'decks']), demand([dataset(4)])).
ml_word('deck', verb, forms(['deck', 'decked', 'decking', 'decks']), demand([dataset(4)])).
ml_word('decompose', verb, forms(['decompose', 'decomposed', 'decomposes', 'decomposing']), demand([question_corpus(7), questioning_paper_lexicon])).
ml_word('decomposed', adjective, forms(['decomposed']), demand([question_corpus(1)])).
ml_word('decorate', verb, forms(['decorate', 'decorated', 'decorates', 'decorating']), demand([question_corpus(1), dataset(10)])).
ml_word('decoration', noun, forms(['decoration', 'decorations']), demand([dataset(31)])).
ml_word('decrease', noun, forms(['decrease', 'decreases']), demand([question_corpus(1), dataset(1)])).
ml_word('decrease', verb, forms(['decrease', 'decreased', 'decreases', 'decreasing']), demand([question_corpus(2), dataset(7)])).
ml_word('deduct', verb, forms(['deduct', 'deducted', 'deducting', 'deducts']), demand([dataset(3)])).
ml_word('deep', noun, forms(['deep', 'deeps']), demand([dataset(2)])).
ml_word('deep', adjective, forms(['deep', 'deeper', 'deepest']), demand([dataset(2)])).
ml_word('deep', adverb, forms(['deep']), demand([dataset(2)])).
ml_word('deepen', verb, forms(['deepen', 'deepened', 'deepening', 'deepens']), demand([question_corpus(1)])).
ml_word('defect', noun, forms(['defect', 'defects']), demand([dataset(25)])).
ml_word('defect', verb, forms(['defect', 'defected', 'defecting', 'defects']), demand([dataset(25)])).
ml_word('deficit', noun, forms(['deficit', 'deficits']), demand([dataset(6)])).
ml_word('deforestation', noun, forms(['deforestation']), demand([question_corpus(1), supplement_class('common_noun')])).
ml_word('degree', noun, forms(['degree', 'degrees']), demand([question_corpus(3), dataset(14)])).
ml_word('delaney', given_name, forms(['delaney']), demand([dataset(8), supplement_class('given_name')])).
ml_word('delay', noun, forms(['delay', 'delays']), demand([dataset(1)])).
ml_word('delay', verb, forms(['delay', 'delayed', 'delaying', 'delays']), demand([dataset(2)])).
ml_word('delete', verb, forms(['delete', 'deleted', 'deletes', 'deleting']), demand([dataset(11)])).
ml_word('deliver', verb, forms(['deliver', 'delivered', 'delivering', 'delivers']), demand([dataset(19)])).
ml_word('deliver', adjective, forms(['deliver']), demand([dataset(13)])).
ml_word('delivery', noun, forms(['deliveries', 'delivery']), demand([dataset(9)])).
ml_word('delta', noun, forms(['delta', 'deltas']), demand([dataset(10)])).
ml_word('demand', noun, forms(['demand', 'demands']), demand([dataset(6)])).
ml_word('demand', verb, forms(['demand', 'demanded', 'demanding', 'demands']), demand([dataset(6)])).
ml_word('demonstrate', verb, forms(['demonstrate', 'demonstrated', 'demonstrates', 'demonstrating']), demand([question_corpus(1)])).
ml_word('denny', given_name, forms(['denny']), demand([dataset(3), supplement_class('given_name')])).
ml_word('denominator', noun, forms(['denominator', 'denominators']), demand([question_corpus(3), questioning_paper_lexicon])).
ml_word('denote', verb, forms(['denote', 'denoted', 'denotes', 'denoting']), demand([dataset(1)])).
ml_word('denver', place_name, forms(['denver']), demand([dataset(16), supplement_class('place_name')])).
ml_word('department', noun, forms(['department', 'departments']), demand([dataset(6)])).
ml_word('depend', verb, forms(['depend', 'depended', 'depending', 'depends']), demand([question_corpus(2), dataset(1)])).
ml_word('dependent', noun, forms(['dependent', 'dependents']), demand([question_corpus(1)])).
ml_word('dependent', adjective, forms(['dependent']), demand([question_corpus(1)])).
ml_word('deposit', noun, forms(['deposit', 'deposits']), demand([dataset(4)])).
ml_word('deposit', verb, forms(['depoited', 'deposit', 'depositing', 'deposits']), demand([dataset(4)])).
ml_word('depth', noun, forms(['depth', 'depths']), demand([dataset(8)])).
ml_word('descend', verb, forms(['descend', 'descended', 'descending', 'descends']), demand([dataset(18)])).
ml_word('descending', adjective, forms(['descending']), demand([dataset(8)])).
ml_word('describe', verb, forms(['describe', 'described', 'describes', 'describing']), demand([question_corpus(25)])).
ml_word('description', noun, forms(['description', 'descriptions']), demand([question_corpus(1)])).
ml_word('descriptor', noun, forms(['descriptor', 'descriptors']), demand([question_corpus(1), supplement_class('math_term')])).
ml_word('deshaun', given_name, forms(['deshaun']), demand([dataset(4), supplement_class('given_name')])).
ml_word('design', noun, forms(['design', 'designs']), demand([question_corpus(3)])).
ml_word('design', verb, forms(['design', 'designed', 'designing', 'designs']), demand([question_corpus(7), dataset(2)])).
ml_word('designer', noun, forms(['designer', 'designers']), demand([dataset(4)])).
ml_word('designing', noun, forms(['designing', 'designings']), demand([dataset(2)])).
ml_word('designing', adjective, forms(['designing']), demand([dataset(2)])).
ml_word('desk', noun, forms(['desk', 'desks']), demand([dataset(65)])).
ml_word('desk', verb, forms(['desk', 'desked', 'desking', 'desks']), demand([dataset(65)])).
ml_word('desktop', noun, forms(['desktop', 'desktops']), demand([question_corpus(1), supplement_class('common_noun')])).
ml_word('desperately', adverb, forms(['desperately']), demand([dataset(2)])).
ml_word('despise', verb, forms(['despise', 'despised', 'despises', 'despising']), demand([dataset(6)])).
ml_word('dessert', noun, forms(['dessert', 'desserts']), demand([question_corpus(1), dataset(16)])).
ml_word('destination', noun, forms(['destination', 'destinations']), demand([dataset(2)])).
ml_word('destroy', verb, forms(['destroy', 'destroyed', 'destroying', 'destroys']), demand([dataset(1)])).
ml_word('detail', noun, forms(['detail', 'details']), demand([dataset(2)])).
ml_word('detail', verb, forms(['detail', 'detailed', 'detailing', 'details']), demand([dataset(2)])).
ml_word('detergent', adjective, forms(['detergent']), demand([dataset(18)])).
ml_word('determine', verb, forms(['determine', 'determined', 'determines', 'determining']), demand([question_corpus(17), dataset(11)])).
ml_word('determined', adjective, forms(['determined']), demand([dataset(6)])).
ml_word('device', noun, forms(['device', 'devices']), demand([question_corpus(2), dataset(2)])).
ml_word('devin', given_name, forms(['devin']), demand([dataset(12), supplement_class('given_name')])).
ml_word('dew', noun, forms(['dew', 'dews']), demand([dataset(4)])).
ml_word('dew', verb, forms(['dew', 'dewed', 'dewing', 'dews']), demand([dataset(4)])).
ml_word('dew', adjective, forms(['dew']), demand([dataset(4)])).
ml_word('diagram', noun, forms(['diagram', 'diagrams']), demand([question_corpus(62), questioning_paper_lexicon])).
ml_word('diagram', verb, forms(['diagram', 'diagramed', 'diagraming', 'diagrams']), demand([question_corpus(62), questioning_paper_lexicon])).
ml_word('diameter', noun, forms(['diameter', 'diameters']), demand([question_corpus(4)])).
ml_word('diane', given_name, forms(['diane']), demand([dataset(1), supplement_class('given_name')])).
ml_word('dianne', given_name, forms(['dianne']), demand([dataset(5), supplement_class('given_name')])).
ml_word('die', noun, forms(['dice', 'die', 'dies']), demand([dataset(3)])).
ml_word('die', verb, forms(['die', 'died', 'dies', 'dying']), demand([dataset(3)])).
ml_word('diego', given_name, forms(['diego']), demand([question_corpus(7), dataset(6), supplement_class('given_name')])).
ml_word('diet', noun, forms(['diet', 'diets']), demand([dataset(3)])).
ml_word('diet', verb, forms(['diet', 'dieted', 'dieting', 'diets']), demand([dataset(3)])).
ml_word('differ', verb, forms(['differ', 'differed', 'differing', 'differs']), demand([question_corpus(1)])).
ml_word('difference', noun, forms(['difference', 'differences']), demand([question_corpus(22), dataset(66), questioning_paper_lexicon])).
ml_word('difference', verb, forms(['difference', 'differenced', 'differences', 'differencing']), demand([question_corpus(22), dataset(66), questioning_paper_lexicon])).
ml_word('different', adjective, forms(['different']), demand([question_corpus(204), dataset(68)])).
ml_word('differently', adverb, forms(['differently']), demand([question_corpus(13)])).
ml_word('difficult', verb, forms(['difficult', 'difficulted', 'difficulting', 'difficults']), demand([question_corpus(4), dataset(2)])).
ml_word('difficult', adjective, forms(['difficult']), demand([question_corpus(4), dataset(2)])).
ml_word('dig', noun, forms(['dig', 'digs']), demand([dataset(22)])).
ml_word('dig', verb, forms(['dig', 'diged', 'digging', 'diging', 'digs', 'dug']), demand([dataset(24)])).
ml_word('digging', noun, forms(['digging', 'diggings']), demand([dataset(2)])).
ml_word('digit', noun, forms(['digit', 'digits']), demand([question_corpus(7)])).
ml_word('digit', verb, forms(['digit', 'digited', 'digiting', 'digits']), demand([question_corpus(7)])).
ml_word('dilation', noun, forms(['dilation', 'dilations']), demand([question_corpus(3), questioning_paper_lexicon])).
ml_word('dime', noun, forms(['dime', 'dimes']), demand([question_corpus(2), dataset(25)])).
ml_word('dimension', noun, forms(['dimension', 'dimensions']), demand([question_corpus(1)])).
ml_word('dimensional', adjective, forms(['dimensional']), demand([question_corpus(1)])).
ml_word('din', verb, forms(['din', 'dined', 'dining', 'dinned', 'dinning', 'dins']), demand([dataset(16)])).
ml_word('dine', verb, forms(['dine', 'dined', 'dines', 'dining']), demand([dataset(16)])).
ml_word('diner', noun, forms(['diner', 'diners']), demand([dataset(4)])).
ml_word('dining', noun, forms(['dining', 'dinings']), demand([dataset(16)])).
ml_word('dining', adjective, forms(['dining']), demand([dataset(16)])).
ml_word('dinner', noun, forms(['dinner', 'dinners']), demand([dataset(72)])).
ml_word('dip', verb, forms(['dip', 'diped', 'diping', 'dipped', 'dipping', 'dips']), demand([dataset(20)])).
ml_word('direction', noun, forms(['direction', 'directions']), demand([question_corpus(2)])).
ml_word('directly', adverb, forms(['directly']), demand([question_corpus(2), dataset(1)])).
ml_word('dirigent', noun, forms(['dirigent', 'dirigents']), demand([webster_domain('geom')])).
ml_word('dirigent', adjective, forms(['dirigent']), demand([webster_domain('geom')])).
ml_word('dirty', verb, forms(['dirtied', 'dirties', 'dirty', 'dirtying']), demand([dataset(1)])).
ml_word('dirty', adjective, forms(['dirtier', 'dirtiest', 'dirty']), demand([dataset(1)])).
ml_word('disagree', verb, forms(['disagree', 'disagreed', 'disagreeing', 'disagrees']), demand([question_corpus(5)])).
ml_word('discount', noun, forms(['discount', 'discounts']), demand([dataset(89)])).
ml_word('discount', verb, forms(['discount', 'discounted', 'discounting', 'discounts']), demand([dataset(94)])).
ml_word('discover', verb, forms(['discover', 'discovered', 'discovering', 'discovers']), demand([dataset(8)])).
ml_word('discrete', verb, forms(['discrete', 'discreted', 'discretes', 'discreting']), demand([question_corpus(1)])).
ml_word('discrete', adjective, forms(['discrete']), demand([question_corpus(1)])).
ml_word('discussion', noun, forms(['discussion', 'discussions']), demand([question_corpus(6)])).
ml_word('dish', noun, forms(['dish', 'dishes']), demand([dataset(88)])).
ml_word('dish', verb, forms(['dish', 'dished', 'dishes', 'dishing']), demand([dataset(88)])).
ml_word('dislike', verb, forms(['dislike', 'disliked', 'dislikes', 'disliking']), demand([dataset(6)])).
ml_word('dismay', noun, forms(['dismay', 'dismays']), demand([dataset(2)])).
ml_word('dismay', verb, forms(['dismay', 'dismayed', 'dismaying', 'dismays']), demand([dataset(2)])).
ml_word('display', noun, forms(['display', 'displays']), demand([question_corpus(4)])).
ml_word('display', verb, forms(['display', 'displayed', 'displaying', 'displays']), demand([question_corpus(4)])).
ml_word('disposable', adjective, forms(['disposable']), demand([question_corpus(1)])).
ml_word('distance', noun, forms(['distance', 'distances']), demand([question_corpus(10), dataset(91)])).
ml_word('distance', verb, forms(['distance', 'distanced', 'distances', 'distancing']), demand([question_corpus(10), dataset(91)])).
ml_word('distinguish', verb, forms(['distinguish', 'distinguished', 'distinguishes', 'distinguishing']), demand([question_corpus(2)])).
ml_word('distribute', verb, forms(['distribute', 'distributed', 'distributes', 'distributing']), demand([question_corpus(1)])).
ml_word('distribution', noun, forms(['distribution', 'distributions']), demand([question_corpus(4), questioning_paper_lexicon])).
ml_word('distributive', noun, forms(['distributive', 'distributives']), demand([questioning_paper_lexicon])).
ml_word('distributive', adjective, forms(['distributive']), demand([questioning_paper_lexicon])).
ml_word('district', noun, forms(['district', 'districts']), demand([question_corpus(1)])).
ml_word('district', verb, forms(['district', 'districted', 'districting', 'districts']), demand([question_corpus(1)])).
ml_word('district', adjective, forms(['district']), demand([question_corpus(1)])).
ml_word('dive', verb, forms(['dive', 'dived', 'dives', 'diving']), demand([dataset(1)])).
ml_word('divide', noun, forms(['divide', 'divides']), demand([question_corpus(4), dataset(82)])).
ml_word('divide', verb, forms(['divide', 'divided', 'divides', 'dividing']), demand([question_corpus(8), dataset(177)])).
ml_word('divided', adjective, forms(['divided']), demand([question_corpus(2), dataset(35)])).
ml_word('dividing', adjective, forms(['dividing']), demand([question_corpus(2), dataset(60)])).
ml_word('diving', adjective, forms(['diving']), demand([dataset(1)])).
ml_word('divisible', noun, forms(['divisible', 'divisibles']), demand([dataset(4)])).
ml_word('divisible', adjective, forms(['divisible']), demand([dataset(4)])).
ml_word('division', noun, forms(['division', 'divisions']), demand([question_corpus(10), questioning_paper_lexicon])).
ml_word('divisor', noun, forms(['divisor', 'divisors']), demand([question_corpus(2)])).
ml_word('do', verb, forms(['did', 'do', 'does', 'doing', 'done']), demand([question_corpus(6), dataset(37)])).
ml_word('doctor', noun, forms(['doctor', 'doctors']), demand([dataset(13)])).
ml_word('doctor', verb, forms(['doctor', 'doctored', 'doctoring', 'doctors']), demand([dataset(13)])).
ml_word('dodgeball', noun, forms(['dodgeball', 'dodgeballs']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('dog', noun, forms(['dog', 'dogs']), demand([question_corpus(6), dataset(252)])).
ml_word('dog', verb, forms(['dog', 'dogged', 'dogging', 'dogs']), demand([question_corpus(6), dataset(252)])).
ml_word('doing', noun, forms(['doing', 'doings']), demand([question_corpus(4), dataset(15)])).
ml_word('dollar', noun, forms(['dollar', 'dollars']), demand([question_corpus(1), dataset(209)])).
ml_word('donate', verb, forms(['donate', 'donated', 'donates', 'donating']), demand([dataset(8)])).
ml_word('done', adjective, forms(['done']), demand([question_corpus(2), dataset(22)])).
ml_word('donna', noun, forms(['donna', 'donnas']), demand([dataset(5)])).
ml_word('donut', noun, forms(['donut', 'donuts']), demand([dataset(69), supplement_class('common_noun')])).
ml_word('door', noun, forms(['door', 'doors']), demand([dataset(38)])).
ml_word('doris', noun, forms(['doris', 'dorises']), demand([dataset(2)])).
ml_word('dorothy', given_name, forms(['dorothy']), demand([dataset(4), supplement_class('given_name')])).
ml_word('dose', noun, forms(['dose', 'doses']), demand([dataset(4)])).
ml_word('dose', verb, forms(['dose', 'dosed', 'doses', 'dosing']), demand([dataset(4)])).
ml_word('dot', noun, forms(['dot', 'dots']), demand([question_corpus(35)])).
ml_word('dot', verb, forms(['dot', 'doted', 'doting', 'dots', 'dotted', 'dotting']), demand([question_corpus(35)])).
ml_word('double', noun, forms(['double', 'doubles']), demand([question_corpus(2), dataset(144)])).
ml_word('double', verb, forms(['double', 'doubled', 'doubles', 'doubling']), demand([question_corpus(4), dataset(170)])).
ml_word('double', adjective, forms(['double']), demand([question_corpus(2), dataset(139)])).
ml_word('double', adverb, forms(['double']), demand([question_corpus(2), dataset(139)])).
ml_word('doubling', noun, forms(['doubling', 'doublings']), demand([dataset(3)])).
ml_word('dough', noun, forms(['dough', 'doughs']), demand([dataset(5)])).
ml_word('doughnut', noun, forms(['doughnut', 'doughnuts']), demand([dataset(4)])).
ml_word('dove', noun, forms(['dove', 'doves']), demand([dataset(26)])).
ml_word('down', noun, forms(['down', 'downs']), demand([question_corpus(2), dataset(133)])).
ml_word('down', verb, forms(['down', 'downed', 'downing', 'downs']), demand([question_corpus(2), dataset(133)])).
ml_word('down', adjective, forms(['down']), demand([question_corpus(2), dataset(133)])).
ml_word('down', adverb, forms(['down']), demand([question_corpus(2), dataset(133)])).
ml_word('down', preposition, forms(['down']), demand([question_corpus(2), dataset(133)])).
ml_word('download', noun, forms(['download', 'downloads']), demand([dataset(80), supplement_class('common_noun')])).
ml_word('download', verb, forms(['download', 'downloaded', 'downloading', 'downloads']), demand([dataset(95), supplement_class('corpus_verb')])).
ml_word('downpayment', noun, forms(['downpayment', 'downpayments']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('dozen', noun, forms(['dozen', 'dozens']), demand([dataset(139)])).
ml_word('dr', honorific, forms(['dr']), demand([dataset(13), supplement_class('honorific')])).
ml_word('drag', verb, forms(['drag', 'draged', 'dragged', 'dragging', 'draging', 'drags']), demand([dataset(2)])).
ml_word('dragon', noun, forms(['dragon', 'dragons']), demand([dataset(16)])).
ml_word('drama', noun, forms(['drama', 'dramas']), demand([dataset(2)])).
ml_word('draper', noun, forms(['draper', 'drapers']), demand([dataset(4)])).
ml_word('draw', noun, forms(['draw', 'draws']), demand([question_corpus(13)])).
ml_word('draw', verb, forms(['draw', 'drawing', 'drawn', 'draws', 'drew']), demand([question_corpus(21), dataset(14)])).
ml_word('drawback', noun, forms(['drawback', 'drawbacks']), demand([question_corpus(3)])).
ml_word('drawing', noun, forms(['drawing', 'drawings']), demand([question_corpus(12)])).
ml_word('dream', noun, forms(['dream', 'dreams']), demand([dataset(26)])).
ml_word('dream', verb, forms(['dream', 'dreamed', 'dreaming', 'dreams']), demand([dataset(28)])).
ml_word('dress', noun, forms(['dress', 'dresses']), demand([dataset(13)])).
ml_word('dress', verb, forms(['dress', 'dressed', 'dresses', 'dressing']), demand([dataset(13)])).
ml_word('drie', verb, forms(['drie', 'dried', 'dries', 'drying']), demand([dataset(5)])).
ml_word('drink', noun, forms(['drink', 'drinks']), demand([question_corpus(2), dataset(109)])).
ml_word('drink', verb, forms(['drank', 'drink', 'drinking', 'drinks', 'drunk']), demand([question_corpus(2), dataset(121)])).
ml_word('drinking', noun, forms(['drinking', 'drinkings']), demand([dataset(11)])).
ml_word('drip', noun, forms(['drip', 'drips']), demand([dataset(5)])).
ml_word('drip', verb, forms(['drip', 'driped', 'driping', 'dripped', 'dripping', 'drips']), demand([dataset(5)])).
ml_word('drive', noun, forms(['drive', 'drives']), demand([question_corpus(2), dataset(79)])).
ml_word('drive', verb, forms(['drive', 'drived', 'driven', 'drives', 'driving', 'drove']), demand([question_corpus(2), dataset(97)])).
ml_word('driver', noun, forms(['driver', 'drivers']), demand([dataset(37)])).
ml_word('driving', noun, forms(['driving', 'drivings']), demand([dataset(9)])).
ml_word('driving', adjective, forms(['driving']), demand([dataset(9)])).
ml_word('drop', noun, forms(['drop', 'drops']), demand([dataset(36)])).
ml_word('drop', verb, forms(['drop', 'droped', 'droping', 'dropped', 'dropping', 'drops']), demand([dataset(67)])).
ml_word('dropper', noun, forms(['dropper', 'droppers']), demand([question_corpus(1)])).
ml_word('dropping', noun, forms(['dropping', 'droppings']), demand([dataset(5)])).
ml_word('drought', noun, forms(['drought', 'droughts']), demand([dataset(2)])).
ml_word('drove', noun, forms(['drove', 'droves']), demand([dataset(2)])).
ml_word('drunk', noun, forms(['drunk', 'drunks']), demand([dataset(1)])).
ml_word('drunk', adjective, forms(['drunk']), demand([dataset(1)])).
ml_word('dry', verb, forms(['dried', 'dries', 'dry', 'drying']), demand([dataset(11)])).
ml_word('dry', adjective, forms(['drier', 'driest', 'dry']), demand([dataset(6)])).
ml_word('due', noun, forms(['due', 'dues']), demand([dataset(20)])).
ml_word('due', verb, forms(['due', 'dued', 'dues', 'duing']), demand([dataset(20)])).
ml_word('due', adjective, forms(['due']), demand([dataset(20)])).
ml_word('due', adverb, forms(['due']), demand([dataset(20)])).
ml_word('dumbbell', noun, forms(['dumbbell', 'dumbbells']), demand([dataset(9), supplement_class('common_noun')])).
ml_word('dump', noun, forms(['dump', 'dumps']), demand([dataset(2)])).
ml_word('dump', verb, forms(['dump', 'dumped', 'dumping', 'dumps']), demand([dataset(2)])).
ml_word('dumpster', noun, forms(['dumpster', 'dumpsters']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('duration', noun, forms(['duration', 'durations']), demand([dataset(20)])).
ml_word('dure', verb, forms(['dure', 'dured', 'dures', 'during']), demand([question_corpus(13), dataset(152)])).
ml_word('during', preposition, forms(['during']), demand([question_corpus(13), dataset(152)])).
ml_word('dust', noun, forms(['dust', 'dusts']), demand([dataset(13)])).
ml_word('dust', verb, forms(['dust', 'dusted', 'dusting', 'dusts']), demand([dataset(13)])).
ml_word('duty', noun, forms(['duties', 'duty']), demand([dataset(2)])).
ml_word('e', algebra_symbol, forms(['e']), demand([question_corpus(1), supplement_class('algebra_symbol')])).
ml_word('eager', noun, forms(['eager', 'eagers']), demand([dataset(2)])).
ml_word('eager', adjective, forms(['eager']), demand([dataset(2)])).
ml_word('ear', noun, forms(['ear', 'ears']), demand([dataset(10)])).
ml_word('ear', verb, forms(['ear', 'eared', 'earing', 'ears']), demand([dataset(10)])).
ml_word('earbud', noun, forms(['earbud', 'earbuds']), demand([dataset(5), supplement_class('common_noun')])).
ml_word('earl', noun, forms(['earl', 'earls']), demand([dataset(8)])).
ml_word('early', adjective, forms(['earlier', 'earliest', 'early']), demand([question_corpus(9), dataset(12)])).
ml_word('early', adverb, forms(['early']), demand([dataset(2)])).
ml_word('earn', noun, forms(['earn', 'earns']), demand([dataset(129)])).
ml_word('earn', verb, forms(['earn', 'earned', 'earning', 'earns']), demand([dataset(257)])).
ml_word('earning', noun, forms(['earning', 'earnings']), demand([dataset(34)])).
ml_word('earring', noun, forms(['earring', 'earrings']), demand([dataset(30)])).
ml_word('east', noun, forms(['east', 'easts']), demand([dataset(7)])).
ml_word('east', verb, forms(['east', 'easted', 'easting', 'easts']), demand([dataset(7)])).
ml_word('east', adjective, forms(['east']), demand([dataset(7)])).
ml_word('east', adverb, forms(['east']), demand([dataset(7)])).
ml_word('easy', adjective, forms(['easier', 'easiest', 'easy']), demand([question_corpus(11)])).
ml_word('eat', verb, forms(['ate', 'eat', 'eated', 'eaten', 'eating', 'eats']), demand([question_corpus(2), dataset(281)])).
ml_word('eating', noun, forms(['eating', 'eatings']), demand([dataset(20)])).
ml_word('economy', noun, forms(['economies', 'economy']), demand([dataset(10)])).
ml_word('edge', noun, forms(['edge', 'edges']), demand([question_corpus(2)])).
ml_word('edge', verb, forms(['edge', 'edged', 'edges', 'edging']), demand([question_corpus(2)])).
ml_word('edition', noun, forms(['edition', 'editions']), demand([dataset(4)])).
ml_word('effective', noun, forms(['effective', 'effectives']), demand([question_corpus(5)])).
ml_word('effective', adjective, forms(['effective']), demand([question_corpus(5)])).
ml_word('effectively', adverb, forms(['effectively']), demand([dataset(1)])).
ml_word('efficient', noun, forms(['efficient', 'efficients']), demand([question_corpus(1)])).
ml_word('efficient', adjective, forms(['efficient']), demand([question_corpus(1)])).
ml_word('effort', noun, forms(['effort', 'efforts']), demand([dataset(1)])).
ml_word('effort', verb, forms(['effort', 'efforted', 'efforting', 'efforts']), demand([dataset(1)])).
ml_word('egg', noun, forms(['egg', 'eggs']), demand([question_corpus(1), dataset(173)])).
ml_word('egg', verb, forms(['egg', 'egged', 'egging', 'eggs']), demand([question_corpus(1), dataset(173)])).
ml_word('eight', noun, forms(['eight', 'eights']), demand([dataset(51)])).
ml_word('eight', adjective, forms(['eight']), demand([dataset(51)])).
ml_word('eighteen', noun, forms(['eighteen', 'eighteens']), demand([dataset(2)])).
ml_word('eighteen', adjective, forms(['eighteen']), demand([dataset(2)])).
ml_word('eighth', noun, forms(['eighth', 'eighths']), demand([question_corpus(1)])).
ml_word('either', adjective, forms(['either']), demand([question_corpus(2), dataset(20)])).
ml_word('either', pronoun, forms(['either']), demand([question_corpus(2), dataset(20)])).
ml_word('either', conjunction, forms(['either']), demand([question_corpus(2), dataset(20)])).
ml_word('elapse', verb, forms(['elapse', 'elapsed', 'elapses', 'elapsing']), demand([question_corpus(1)])).
ml_word('elect', verb, forms(['elect', 'elected', 'electing', 'elects']), demand([dataset(6)])).
ml_word('electric', noun, forms(['electric', 'electrics']), demand([dataset(9)])).
ml_word('electric', adjective, forms(['electric']), demand([dataset(9)])).
ml_word('electronics', noun, forms(['electronics']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('element', noun, forms(['element', 'elements']), demand([dataset(16)])).
ml_word('element', verb, forms(['element', 'elemented', 'elementing', 'elements']), demand([dataset(16)])).
ml_word('elementary', adjective, forms(['elementary']), demand([dataset(2)])).
ml_word('elena', given_name, forms(['elena']), demand([question_corpus(7), supplement_class('given_name')])).
ml_word('elevation', noun, forms(['elevation', 'elevations']), demand([question_corpus(3), dataset(12)])).
ml_word('elevator', noun, forms(['elevator', 'elevators']), demand([dataset(46)])).
ml_word('eliana', given_name, forms(['eliana']), demand([dataset(8), supplement_class('given_name')])).
ml_word('eliminant', noun, forms(['eliminant', 'eliminants']), demand([webster_domain('math')])).
ml_word('elise', given_name, forms(['elise']), demand([dataset(30), supplement_class('given_name')])).
ml_word('ella', given_name, forms(['ella']), demand([dataset(22), supplement_class('given_name')])).
ml_word('elliott', given_name, forms(['elliott']), demand([dataset(42), supplement_class('given_name')])).
ml_word('elsa', given_name, forms(['elsa']), demand([dataset(6), supplement_class('given_name')])).
ml_word('else', adjective, forms(['else']), demand([question_corpus(9)])).
ml_word('else', adverb, forms(['else']), demand([question_corpus(9)])).
ml_word('else', pronoun, forms(['else']), demand([question_corpus(9)])).
ml_word('else', conjunction, forms(['else']), demand([question_corpus(9)])).
ml_word('email', noun, forms(['email', 'emails']), demand([dataset(27), supplement_class('common_noun')])).
ml_word('emily', given_name, forms(['emily']), demand([dataset(10), supplement_class('given_name')])).
ml_word('emma', given_name, forms(['emma']), demand([dataset(10), supplement_class('given_name')])).
ml_word('employ', verb, forms(['employ', 'employed', 'employing', 'employs']), demand([dataset(5)])).
ml_word('employment', noun, forms(['employment', 'employments']), demand([dataset(1)])).
ml_word('empty', noun, forms(['empties', 'empty']), demand([dataset(16)])).
ml_word('empty', verb, forms(['emptied', 'empties', 'empty', 'emptying']), demand([dataset(18)])).
ml_word('empty', adjective, forms(['emptier', 'emptiest', 'empty']), demand([dataset(14)])).
ml_word('emu', noun, forms(['emu', 'emus']), demand([dataset(11)])).
ml_word('enable', verb, forms(['enable', 'enabled', 'enables', 'enabling']), demand([question_corpus(1)])).
ml_word('enchant', verb, forms(['enchant', 'enchanted', 'enchanting', 'enchants']), demand([dataset(2)])).
ml_word('enchanted', adjective, forms(['enchanted']), demand([dataset(2)])).
ml_word('enclosure', noun, forms(['enclosure', 'enclosures']), demand([dataset(4)])).
ml_word('encourage', verb, forms(['encourage', 'encouraged', 'encourages', 'encouraging']), demand([question_corpus(5), supplement_class('corpus_verb')])).
ml_word('end', noun, forms(['end', 'ends']), demand([question_corpus(2), dataset(92)])).
ml_word('end', verb, forms(['end', 'ended', 'ending', 'ends']), demand([question_corpus(2), dataset(99)])).
ml_word('endanger', verb, forms(['endanger', 'endangered', 'endangering', 'endangers']), demand([dataset(2)])).
ml_word('engage', verb, forms(['engage', 'engaged', 'engages', 'engaging']), demand([question_corpus(1)])).
ml_word('engagement', noun, forms(['engagement', 'engagements']), demand([question_corpus(2), dataset(1)])).
ml_word('engine', noun, forms(['engine', 'engines']), demand([dataset(4)])).
ml_word('engine', verb, forms(['engine', 'engined', 'engines', 'engining']), demand([dataset(4)])).
ml_word('engineer', noun, forms(['engineer', 'engineers']), demand([dataset(2)])).
ml_word('engineer', verb, forms(['engineer', 'engineered', 'engineering', 'engineers']), demand([dataset(2)])).
ml_word('english', noun, forms(['english', 'englishes']), demand([dataset(2)])).
ml_word('english', verb, forms(['english', 'englished', 'englishes', 'englishing']), demand([dataset(2)])).
ml_word('english', adjective, forms(['english']), demand([dataset(2)])).
ml_word('enjoy', verb, forms(['enjoy', 'enjoyed', 'enjoying', 'enjoys']), demand([question_corpus(2), dataset(5)])).
ml_word('enneahedria', noun, forms(['enneahedria', 'enneahedrias']), demand([webster_domain('geom')])).
ml_word('enneahedron', noun, forms(['enneahedron', 'enneahedrons']), demand([webster_domain('geom')])).
ml_word('enormous', adjective, forms(['enormous']), demand([dataset(2)])).
ml_word('enough', noun, forms(['enough', 'enoughs']), demand([question_corpus(5), dataset(122)])).
ml_word('enough', adjective, forms(['enough']), demand([question_corpus(5), dataset(122)])).
ml_word('enough', adverb, forms(['enough']), demand([question_corpus(5), dataset(122)])).
ml_word('enough', interjection, forms(['enough']), demand([question_corpus(5), dataset(122)])).
ml_word('ensure', verb, forms(['ensure', 'ensured', 'ensures', 'ensuring']), demand([question_corpus(4), dataset(8)])).
ml_word('enter', verb, forms(['enter', 'entered', 'entering', 'enters']), demand([dataset(4)])).
ml_word('entire', noun, forms(['entire', 'entires']), demand([question_corpus(2), dataset(62)])).
ml_word('entire', adjective, forms(['entire']), demand([question_corpus(2), dataset(62)])).
ml_word('entitle', verb, forms(['entitle', 'entitled', 'entitles', 'entitling']), demand([dataset(16)])).
ml_word('episode', noun, forms(['episode', 'episodes']), demand([question_corpus(1), dataset(37)])).
ml_word('equal', noun, forms(['equal', 'equals']), demand([question_corpus(22), dataset(148), questioning_paper_lexicon])).
ml_word('equal', verb, forms(['equal', 'equaled', 'equaling', 'equals']), demand([question_corpus(22), dataset(148), questioning_paper_lexicon])).
ml_word('equal', adjective, forms(['equal']), demand([question_corpus(18), dataset(116), questioning_paper_lexicon])).
ml_word('equally', adverb, forms(['equally']), demand([question_corpus(1), dataset(37)])).
ml_word('equation', noun, forms(['equation', 'equations']), demand([question_corpus(89), dataset(108), questioning_paper_lexicon])).
ml_word('equator', noun, forms(['equator', 'equators']), demand([question_corpus(1)])).
ml_word('equilateral', noun, forms(['equilateral', 'equilaterals']), demand([question_corpus(1)])).
ml_word('equilateral', adjective, forms(['equilateral']), demand([question_corpus(1)])).
ml_word('equimultiple', noun, forms(['equimultiple', 'equimultiples']), demand([webster_domain('math')])).
ml_word('equimultiple', adjective, forms(['equimultiple']), demand([webster_domain('math')])).
ml_word('equivalence', noun, forms(['equivalence', 'equivalences']), demand([question_corpus(1)])).
ml_word('equivalence', verb, forms(['equivalence', 'equivalenced', 'equivalences', 'equivalencing']), demand([question_corpus(1)])).
ml_word('equivalent', noun, forms(['equivalent', 'equivalents']), demand([question_corpus(13), dataset(7), questioning_paper_lexicon])).
ml_word('equivalent', verb, forms(['equivalent', 'equivalented', 'equivalenting', 'equivalents']), demand([question_corpus(13), dataset(7), questioning_paper_lexicon])).
ml_word('equivalent', adjective, forms(['equivalent']), demand([question_corpus(13), dataset(7), questioning_paper_lexicon])).
ml_word('eraser', noun, forms(['eraser', 'erasers']), demand([question_corpus(1), dataset(58)])).
ml_word('eric', noun, forms(['eric', 'erics']), demand([dataset(12)])).
ml_word('erin', noun, forms(['erin', 'erins']), demand([dataset(12)])).
ml_word('error', noun, forms(['error', 'errors']), demand([question_corpus(1), dataset(1)])).
ml_word('escape', noun, forms(['escape', 'escapes']), demand([dataset(12)])).
ml_word('escape', verb, forms(['escape', 'escaped', 'escapes', 'escaping']), demand([dataset(14)])).
ml_word('eskimo', noun, forms(['eskimo', 'eskimos']), demand([dataset(2)])).
ml_word('especially', adverb, forms(['especially']), demand([question_corpus(1)])).
ml_word('espresso', noun, forms(['espresso', 'espressos']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('essay', noun, forms(['essay', 'essays']), demand([dataset(4)])).
ml_word('essay', verb, forms(['essay', 'essayed', 'essaying', 'essays']), demand([dataset(4)])).
ml_word('estimate', noun, forms(['estimate', 'estimates']), demand([question_corpus(110)])).
ml_word('estimate', verb, forms(['estimate', 'estimated', 'estimates', 'estimating']), demand([question_corpus(112), dataset(2)])).
ml_word('estimation', noun, forms(['estimation', 'estimations']), demand([question_corpus(2)])).
ml_word('etc', abbreviation, forms(['etc']), demand([dataset(1), supplement_class('abbreviation')])).
ml_word('ethereum', named_entity, forms(['ethereum']), demand([dataset(3), supplement_class('named_entity')])).
ml_word('euro', noun, forms(['euro', 'euros']), demand([dataset(10), supplement_class('common_noun')])).
ml_word('eva', given_name, forms(['eva']), demand([dataset(4), supplement_class('given_name')])).
ml_word('evaluate', verb, forms(['evaluate', 'evaluated', 'evaluates', 'evaluating']), demand([question_corpus(4)])).
ml_word('evaporate', verb, forms(['evaporate', 'evaporated', 'evaporates', 'evaporating']), demand([dataset(6)])).
ml_word('evaporate', adjective, forms(['evaporate']), demand([dataset(6)])).
ml_word('even', verb, forms(['even', 'evened', 'evening', 'evens']), demand([question_corpus(5), dataset(36)])).
ml_word('even', adjective, forms(['even']), demand([question_corpus(5), dataset(14)])).
ml_word('even', adverb, forms(['even']), demand([question_corpus(5), dataset(14)])).
ml_word('evene', verb, forms(['evene', 'evened', 'evenes', 'evening']), demand([dataset(22)])).
ml_word('evening', noun, forms(['evening', 'evenings']), demand([dataset(22)])).
ml_word('evenly', adverb, forms(['evenly']), demand([dataset(25)])).
ml_word('event', noun, forms(['event', 'events']), demand([question_corpus(4), dataset(41)])).
ml_word('event', verb, forms(['event', 'evented', 'eventing', 'events']), demand([question_corpus(4), dataset(41)])).
ml_word('eventually', adverb, forms(['eventually']), demand([dataset(10)])).
ml_word('ever', adverb, forms(['ever']), demand([question_corpus(1), dataset(2), supplement_class('adverb')])).
ml_word('every', adjective, forms(['every']), demand([question_corpus(2), dataset(410)])).
ml_word('everyone', noun, forms(['everyone', 'everyones']), demand([question_corpus(4), dataset(22)])).
ml_word('everything', noun, forms(['everything', 'everythings']), demand([dataset(5)])).
ml_word('everywhere', adverb, forms(['everywhere']), demand([dataset(2)])).
ml_word('evidence', noun, forms(['evidence', 'evidences']), demand([question_corpus(3)])).
ml_word('evidence', verb, forms(['evidence', 'evidenced', 'evidences', 'evidencing']), demand([question_corpus(3)])).
ml_word('exact', verb, forms(['exact', 'exacted', 'exacting', 'exacts']), demand([question_corpus(4), dataset(6)])).
ml_word('exact', adjective, forms(['exact']), demand([question_corpus(4), dataset(6)])).
ml_word('exactly', adverb, forms(['exactly']), demand([question_corpus(6), dataset(11)])).
ml_word('exam', noun, forms(['exam', 'exams']), demand([dataset(14), supplement_class('common_noun')])).
ml_word('examination', noun, forms(['examination', 'examinations']), demand([dataset(2)])).
ml_word('example', noun, forms(['example', 'examples']), demand([question_corpus(10)])).
ml_word('example', verb, forms(['example', 'exampled', 'examples', 'exampling']), demand([question_corpus(10)])).
ml_word('exceed', verb, forms(['exceed', 'exceeded', 'exceeding', 'exceeds']), demand([dataset(3)])).
ml_word('except', verb, forms(['except', 'excepted', 'excepting', 'excepts']), demand([dataset(13)])).
ml_word('except', preposition, forms(['except']), demand([dataset(13)])).
ml_word('except', conjunction, forms(['except']), demand([dataset(13)])).
ml_word('exchange', noun, forms(['exchange', 'exchanges']), demand([dataset(2)])).
ml_word('exchange', verb, forms(['exchange', 'exchanged', 'exchanges', 'exchanging']), demand([dataset(2)])).
ml_word('exercise', noun, forms(['exercise', 'exercises']), demand([question_corpus(1), dataset(2)])).
ml_word('exercise', verb, forms(['exercise', 'exercised', 'exercises', 'exercising']), demand([question_corpus(1), dataset(8)])).
ml_word('exit', noun, forms(['exit', 'exits']), demand([dataset(4)])).
ml_word('expand', verb, forms(['expand', 'expanded', 'expanding', 'expands']), demand([question_corpus(3), dataset(2)])).
ml_word('expanding', adjective, forms(['expanding']), demand([question_corpus(1), dataset(2)])).
ml_word('expect', noun, forms(['expect', 'expects']), demand([question_corpus(2)])).
ml_word('expect', verb, forms(['expect', 'expected', 'expecting', 'expects']), demand([question_corpus(3)])).
ml_word('expense', noun, forms(['expense', 'expenses']), demand([dataset(19)])).
ml_word('expensive', adjective, forms(['expensive']), demand([dataset(13)])).
ml_word('experience', noun, forms(['experience', 'experiences']), demand([question_corpus(1)])).
ml_word('experience', verb, forms(['experience', 'experienced', 'experiences', 'experiencing']), demand([question_corpus(1), dataset(2)])).
ml_word('experiment', noun, forms(['experiment', 'experiments']), demand([question_corpus(1)])).
ml_word('experiment', verb, forms(['experiment', 'experimented', 'experimenting', 'experiments', 'experinenting']), demand([question_corpus(1), supplement_class('corpus_verb')])).
ml_word('experimental', adjective, forms(['experimental']), demand([dataset(2)])).
ml_word('explain', verb, forms(['explain', 'explained', 'explaining', 'explains']), demand([question_corpus(40)])).
ml_word('explanation', noun, forms(['explanation', 'explanations']), demand([question_corpus(1)])).
ml_word('explode', verb, forms(['explode', 'exploded', 'explodes', 'exploding']), demand([dataset(40)])).
ml_word('exploration', noun, forms(['exploration', 'explorations']), demand([question_corpus(1)])).
ml_word('exponent', noun, forms(['exponent', 'exponents']), demand([question_corpus(2), questioning_paper_lexicon])).
ml_word('express', noun, forms(['express', 'expresses']), demand([question_corpus(2), dataset(1)])).
ml_word('express', verb, forms(['express', 'expressed', 'expresses', 'expressing']), demand([question_corpus(3), dataset(10)])).
ml_word('express', adjective, forms(['express']), demand([question_corpus(2), dataset(1)])).
ml_word('expression', noun, forms(['expression', 'expressions']), demand([question_corpus(172), dataset(2), questioning_paper_lexicon])).
ml_word('extra', noun, forms(['extra', 'extras']), demand([question_corpus(1), dataset(58)])).
ml_word('extra', adjective, forms(['extra']), demand([question_corpus(1), dataset(58)])).
ml_word('extracurricular', noun, forms(['extracurricular', 'extracurriculars']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('extracurricular', adjective, forms(['extracurricular']), demand([dataset(5), supplement_class('adjective')])).
ml_word('eye', noun, forms(['eye', 'eyes']), demand([dataset(40)])).
ml_word('eye', verb, forms(['eye', 'eyed', 'eyes', 'eying']), demand([dataset(40)])).
ml_word('fabric', noun, forms(['fabric', 'fabrics']), demand([question_corpus(1), dataset(7)])).
ml_word('fabric', verb, forms(['fabric', 'fabricked', 'fabricking', 'fabrics']), demand([question_corpus(1), dataset(7)])).
ml_word('face', verb, forms(['face', 'faced', 'faces', 'facing']), demand([question_corpus(1)])).
ml_word('faced', adjective, forms(['faced']), demand([question_corpus(1)])).
ml_word('fact', noun, forms(['fact', 'facts']), demand([question_corpus(4), dataset(1)])).
ml_word('factor', noun, forms(['factor', 'factors']), demand([question_corpus(11), questioning_paper_lexicon])).
ml_word('factor', verb, forms(['factor', 'factored', 'factoring', 'factors']), demand([question_corpus(11), questioning_paper_lexicon, webster_domain('math')])).
ml_word('factorial', noun, forms(['factorial', 'factorials']), demand([webster_domain('math')])).
ml_word('factorial', adjective, forms(['factorial']), demand([webster_domain('math')])).
ml_word('factoring', noun, forms(['factoring', 'factorings']), demand([webster_domain('math')])).
ml_word('factory', noun, forms(['factories', 'factory']), demand([dataset(23)])).
ml_word('fail', noun, forms(['fail', 'fails']), demand([dataset(4)])).
ml_word('fail', verb, forms(['fail', 'failed', 'failing', 'fails']), demand([dataset(10)])).
ml_word('fair', noun, forms(['fair', 'fairs']), demand([question_corpus(8), dataset(12)])).
ml_word('fair', verb, forms(['fair', 'faired', 'fairing', 'fairs']), demand([question_corpus(8), dataset(12)])).
ml_word('fair', adjective, forms(['fair', 'fairer', 'fairest']), demand([question_corpus(8), dataset(12)])).
ml_word('fair', adverb, forms(['fair']), demand([question_corpus(8), dataset(12)])).
ml_word('fall', noun, forms(['fall', 'falls']), demand([dataset(14)])).
ml_word('fall', verb, forms(['fall', 'falled', 'falling', 'falls']), demand([dataset(14)])).
ml_word('false', verb, forms(['false', 'falsed', 'falses', 'falsing']), demand([question_corpus(10)])).
ml_word('false', adjective, forms(['false', 'falser', 'falsest']), demand([question_corpus(10)])).
ml_word('false', adverb, forms(['false']), demand([question_corpus(10)])).
ml_word('family', noun, forms(['families', 'family']), demand([question_corpus(7), dataset(72)])).
ml_word('famous', adjective, forms(['famous']), demand([dataset(6)])).
ml_word('fancy', noun, forms(['fancies', 'fancy']), demand([dataset(2)])).
ml_word('fancy', verb, forms(['fancied', 'fancies', 'fancy', 'fancyed', 'fancying']), demand([dataset(2)])).
ml_word('fancy', adjective, forms(['fancy']), demand([dataset(2)])).
ml_word('far', noun, forms(['far', 'fars']), demand([question_corpus(6), dataset(32)])).
ml_word('far', adjective, forms(['far']), demand([question_corpus(6), dataset(32)])).
ml_word('far', adverb, forms(['far']), demand([question_corpus(6), dataset(32)])).
ml_word('farm', noun, forms(['farm', 'farms']), demand([dataset(7)])).
ml_word('farm', verb, forms(['farm', 'farmed', 'farming', 'farms']), demand([dataset(7)])).
ml_word('farmer', noun, forms(['farmer', 'farmers']), demand([dataset(30)])).
ml_word('fashion', noun, forms(['fashion', 'fashions']), demand([dataset(4)])).
ml_word('fashion', verb, forms(['fashion', 'fashioned', 'fashioning', 'fashions']), demand([dataset(4)])).
ml_word('fast', noun, forms(['fast', 'fasts']), demand([question_corpus(1), dataset(19)])).
ml_word('fast', verb, forms(['fast', 'fasted', 'fasting', 'fasts']), demand([question_corpus(1), dataset(19)])).
ml_word('fast', adjective, forms(['fast', 'faster', 'fastest']), demand([question_corpus(3), dataset(40)])).
ml_word('fast', adverb, forms(['fast']), demand([question_corpus(1), dataset(19)])).
ml_word('faster', noun, forms(['faster', 'fasters']), demand([question_corpus(1), dataset(18)])).
ml_word('fat', noun, forms(['fat', 'fats']), demand([dataset(7)])).
ml_word('fat', verb, forms(['fat', 'fated', 'fating', 'fats', 'fatted', 'fatting']), demand([dataset(7)])).
ml_word('fat', adjective, forms(['fat', 'fatter', 'fattest']), demand([dataset(7)])).
ml_word('father', noun, forms(['father', 'fathers']), demand([question_corpus(1), dataset(76)])).
ml_word('father', verb, forms(['father', 'fathered', 'fathering', 'fathers']), demand([question_corpus(1), dataset(76)])).
ml_word('fatima', given_name, forms(['fatima']), demand([dataset(5), supplement_class('given_name')])).
ml_word('favor', noun, forms(['favor', 'favors']), demand([dataset(4)])).
ml_word('favor', verb, forms(['favor', 'favored', 'favoring', 'favors']), demand([dataset(4)])).
ml_word('favorite', noun, forms(['favorite', 'favorites']), demand([question_corpus(12), dataset(17)])).
ml_word('favorite', adjective, forms(['favorite']), demand([question_corpus(12), dataset(17)])).
ml_word('feather', noun, forms(['feather', 'feathers']), demand([dataset(27)])).
ml_word('feather', verb, forms(['feather', 'feathered', 'feathering', 'feathers']), demand([dataset(27)])).
ml_word('feature', noun, forms(['feature', 'features']), demand([question_corpus(1), dataset(6)])).
ml_word('federal', noun, forms(['federal', 'federals']), demand([dataset(2)])).
ml_word('federal', adjective, forms(['federal']), demand([dataset(2)])).
ml_word('fee', noun, forms(['fee', 'fees']), demand([dataset(10)])).
ml_word('fee', verb, forms(['fee', 'feed', 'feeing', 'fees']), demand([dataset(171)])).
ml_word('feed', noun, forms(['feed', 'feeds']), demand([dataset(188)])).
ml_word('feed', verb, forms(['fed', 'feed', 'feeded', 'feeding', 'feeds']), demand([dataset(189)])).
ml_word('feedback', noun, forms(['feedback']), demand([question_corpus(1), supplement_class('common_noun')])).
ml_word('feeding', noun, forms(['feeding', 'feedings']), demand([dataset(1)])).
ml_word('feel', noun, forms(['feel', 'feels']), demand([question_corpus(3)])).
ml_word('feel', verb, forms(['feel', 'feeling', 'feels', 'felt']), demand([question_corpus(3), dataset(6)])).
ml_word('feet', noun, forms(['feet', 'feets']), demand([question_corpus(9), dataset(267)])).
ml_word('felicity', noun, forms(['felicities', 'felicity']), demand([dataset(5)])).
ml_word('fell', noun, forms(['fell', 'fells']), demand([dataset(6)])).
ml_word('fell', verb, forms(['fell', 'felled', 'felling', 'fells']), demand([dataset(6)])).
ml_word('fell', adjective, forms(['fell']), demand([dataset(6)])).
ml_word('felt', noun, forms(['felt', 'felts']), demand([dataset(6)])).
ml_word('felt', verb, forms(['felt', 'felted', 'felting', 'felts']), demand([dataset(6)])).
ml_word('female', noun, forms(['female', 'females']), demand([dataset(79)])).
ml_word('female', adjective, forms(['female']), demand([dataset(37)])).
ml_word('fence', noun, forms(['fence', 'fences']), demand([dataset(2)])).
ml_word('fence', verb, forms(['fence', 'fenced', 'fences', 'fencing']), demand([dataset(10)])).
ml_word('fencing', noun, forms(['fencing', 'fencings']), demand([dataset(8)])).
ml_word('fern', noun, forms(['fern', 'ferns']), demand([dataset(9)])).
ml_word('fern', adjective, forms(['fern']), demand([dataset(9)])).
ml_word('fern', adverb, forms(['fern']), demand([dataset(9)])).
ml_word('fernando', given_name, forms(['fernando']), demand([dataset(6), supplement_class('given_name')])).
ml_word('few', adjective, forms(['few', 'fewer', 'fewest']), demand([question_corpus(9), dataset(43)])).
ml_word('field', noun, forms(['field', 'fields']), demand([question_corpus(1), dataset(83)])).
ml_word('field', verb, forms(['field', 'fielded', 'fielding', 'fields']), demand([question_corpus(1), dataset(83)])).
ml_word('fifteen', noun, forms(['fifteen', 'fifteens']), demand([dataset(1)])).
ml_word('fifteen', adjective, forms(['fifteen']), demand([dataset(1)])).
ml_word('fifth', noun, forms(['fifth', 'fifths']), demand([dataset(22)])).
ml_word('fifth', adjective, forms(['fifth']), demand([dataset(7)])).
ml_word('fifty', noun, forms(['fifties', 'fifty']), demand([dataset(4)])).
ml_word('fifty', adjective, forms(['fifty']), demand([dataset(4)])).
ml_word('fight', verb, forms(['fight', 'fighting', 'fights', 'fought']), demand([question_corpus(1)])).
ml_word('fighting', adjective, forms(['fighting']), demand([question_corpus(1)])).
ml_word('figure', noun, forms(['figure', 'figures']), demand([question_corpus(36), dataset(19)])).
ml_word('figure', verb, forms(['figure', 'figured', 'figures', 'figuring']), demand([question_corpus(39), dataset(22)])).
ml_word('figured', adjective, forms(['figured']), demand([question_corpus(2)])).
ml_word('file', noun, forms(['file', 'files']), demand([dataset(50)])).
ml_word('file', verb, forms(['file', 'filed', 'files', 'filing']), demand([dataset(50)])).
ml_word('fill', noun, forms(['fill', 'fills']), demand([question_corpus(5), dataset(127)])).
ml_word('fill', verb, forms(['fill', 'filled', 'filling', 'fills']), demand([question_corpus(9), dataset(192)])).
ml_word('filling', noun, forms(['filling', 'fillings']), demand([question_corpus(2), dataset(28)])).
ml_word('film', noun, forms(['film', 'films']), demand([dataset(8)])).
ml_word('film', verb, forms(['film', 'filmed', 'filming', 'films']), demand([dataset(8)])).
ml_word('final', adjective, forms(['final']), demand([question_corpus(2), dataset(74)])).
ml_word('finally', adverb, forms(['finally']), demand([dataset(60)])).
ml_word('find', noun, forms(['find', 'finds']), demand([question_corpus(110), dataset(411)])).
ml_word('find', verb, forms(['find', 'finding', 'finds', 'found']), demand([question_corpus(153), dataset(463)])).
ml_word('finding', noun, forms(['finding', 'findings']), demand([question_corpus(34), dataset(22)])).
ml_word('fine', noun, forms(['fine', 'fines']), demand([dataset(2)])).
ml_word('fine', verb, forms(['fine', 'fined', 'fines', 'fining']), demand([dataset(2)])).
ml_word('fine', adjective, forms(['fine', 'finer', 'finest']), demand([dataset(2)])).
ml_word('finger', noun, forms(['finger', 'fingers']), demand([question_corpus(9)])).
ml_word('finger', verb, forms(['finger', 'fingered', 'fingering', 'fingers']), demand([question_corpus(9)])).
ml_word('finish', noun, forms(['finish', 'finishes']), demand([question_corpus(3), dataset(67)])).
ml_word('finish', verb, forms(['finish', 'finished', 'finishes', 'finishing']), demand([question_corpus(3), dataset(134)])).
ml_word('finished', adjective, forms(['finished']), demand([dataset(55)])).
ml_word('finishing', noun, forms(['finishing', 'finishings']), demand([dataset(12)])).
ml_word('finishing', adjective, forms(['finishing']), demand([dataset(12)])).
ml_word('fire', noun, forms(['fire', 'fires']), demand([dataset(10)])).
ml_word('fire', verb, forms(['fire', 'fired', 'fires', 'firing', 'fring']), demand([dataset(10)])).
ml_word('first', noun, forms(['first', 'firsts']), demand([question_corpus(66), dataset(530)])).
ml_word('first', adjective, forms(['first']), demand([question_corpus(66), dataset(530)])).
ml_word('first', adverb, forms(['first']), demand([question_corpus(66), dataset(530)])).
ml_word('fish', noun, forms(['fish', 'fishes']), demand([question_corpus(2), dataset(94)])).
ml_word('fish', verb, forms(['fish', 'fished', 'fishes', 'fishing']), demand([question_corpus(2), dataset(94)])).
ml_word('fit', noun, forms(['fit', 'fits']), demand([question_corpus(8), dataset(29)])).
ml_word('fit', verb, forms(['fit', 'fited', 'fiting', 'fits', 'fitted', 'fitting']), demand([question_corpus(8), dataset(29)])).
ml_word('fit', adjective, forms(['fit', 'fitter', 'fittest']), demand([question_corpus(8), dataset(29)])).
ml_word('five', noun, forms(['five', 'fives']), demand([dataset(135)])).
ml_word('five', adjective, forms(['five']), demand([dataset(135)])).
ml_word('fix', noun, forms(['fix', 'fixes']), demand([question_corpus(1), dataset(2)])).
ml_word('fix', verb, forms(['fix', 'fixed', 'fixes', 'fixing']), demand([question_corpus(1), dataset(4)])).
ml_word('fix', adjective, forms(['fix']), demand([question_corpus(1), dataset(2)])).
ml_word('fixed', adjective, forms(['fixed']), demand([dataset(2)])).
ml_word('flag', noun, forms(['flag', 'flags']), demand([question_corpus(1)])).
ml_word('flag', verb, forms(['flag', 'flaged', 'flagged', 'flagging', 'flaging', 'flags']), demand([question_corpus(1)])).
ml_word('flame', noun, forms(['flame', 'flames']), demand([dataset(9)])).
ml_word('flame', verb, forms(['flame', 'flamed', 'flames', 'flaming']), demand([dataset(9)])).
ml_word('flamethrower', noun, forms(['flamethrower', 'flamethrowers']), demand([dataset(1), supplement_class('common_noun')])).
ml_word('flamingo', noun, forms(['flamingo', 'flamingoes', 'flamingos']), demand([dataset(12)])).
ml_word('flash', verb, forms(['flash', 'flashed', 'flashes', 'flashing']), demand([question_corpus(1)])).
ml_word('flat', noun, forms(['flat', 'flats']), demand([question_corpus(1), dataset(2)])).
ml_word('flat', verb, forms(['flat', 'flated', 'flating', 'flats', 'flatted', 'flatting']), demand([question_corpus(1), dataset(2)])).
ml_word('flat', adjective, forms(['flat', 'flatter', 'flattest']), demand([question_corpus(1)])).
ml_word('flat', adverb, forms(['flat']), demand([question_corpus(1)])).
ml_word('flaw', verb, forms(['flaw', 'flawed', 'flawing', 'flaws']), demand([question_corpus(1)])).
ml_word('fletcher', noun, forms(['fletcher', 'fletchers']), demand([dataset(5)])).
ml_word('flight', noun, forms(['flight', 'flights']), demand([dataset(32)])).
ml_word('flip', verb, forms(['flip', 'flipped', 'flipping', 'flips']), demand([dataset(12)])).
ml_word('float', noun, forms(['float', 'floats']), demand([dataset(6)])).
ml_word('float', verb, forms(['float', 'floated', 'floating', 'floats']), demand([dataset(6)])).
ml_word('flock', noun, forms(['flock', 'flocks']), demand([dataset(51)])).
ml_word('flock', verb, forms(['flock', 'flocked', 'flocking', 'flocks']), demand([dataset(51)])).
ml_word('floor', noun, forms(['floor', 'floors']), demand([question_corpus(3), dataset(182)])).
ml_word('floor', verb, forms(['floor', 'floored', 'flooring', 'floors']), demand([question_corpus(3), dataset(182)])).
ml_word('flora', noun, forms(['flora', 'floras']), demand([dataset(10)])).
ml_word('flour', noun, forms(['flour', 'flours']), demand([dataset(32)])).
ml_word('flour', verb, forms(['flour', 'floured', 'flouring', 'flours']), demand([dataset(32)])).
ml_word('flow', noun, forms(['flow', 'flows']), demand([dataset(8)])).
ml_word('flow', verb, forms(['flow', 'flowed', 'flowing', 'flows']), demand([dataset(8)])).
ml_word('flower', noun, forms(['flower', 'flowers']), demand([question_corpus(2), dataset(22)])).
ml_word('flower', verb, forms(['flower', 'flowered', 'flowering', 'flowers']), demand([question_corpus(2), dataset(22)])).
ml_word('flown', adjective, forms(['flown']), demand([dataset(1)])).
ml_word('fluid', noun, forms(['fluid', 'fluids']), demand([dataset(2)])).
ml_word('fluid', adjective, forms(['fluid']), demand([dataset(2)])).
ml_word('fluxion', noun, forms(['fluxion', 'fluxions']), demand([webster_domain('math')])).
ml_word('fluxions', noun, forms(['fluxions']), demand([webster_domain('math')])).
ml_word('fly', noun, forms(['flies', 'fly']), demand([dataset(72)])).
ml_word('fly', verb, forms(['flew', 'flies', 'flown', 'fly', 'flyed', 'flying']), demand([dataset(84)])).
ml_word('fly', adjective, forms(['fly']), demand([dataset(16)])).
ml_word('flying', adjective, forms(['flying']), demand([dataset(9)])).
ml_word('foam', noun, forms(['foam', 'foams']), demand([question_corpus(1)])).
ml_word('foam', verb, forms(['foam', 'foamed', 'foaming', 'foams']), demand([question_corpus(1)])).
ml_word('fold', noun, forms(['fold', 'folds']), demand([question_corpus(1)])).
ml_word('fold', verb, forms(['fold', 'folded', 'folding', 'folds']), demand([question_corpus(1)])).
ml_word('follow', verb, forms(['follow', 'followed', 'following', 'follows']), demand([question_corpus(2), dataset(17)])).
ml_word('follower', noun, forms(['follower', 'followers']), demand([dataset(15)])).
ml_word('following', noun, forms(['following', 'followings']), demand([question_corpus(1), dataset(9)])).
ml_word('following', adjective, forms(['following']), demand([question_corpus(1), dataset(9)])).
ml_word('food', noun, forms(['food', 'foods']), demand([question_corpus(3), dataset(118)])).
ml_word('food', verb, forms(['food', 'fooded', 'fooding', 'foods']), demand([question_corpus(3), dataset(118)])).
ml_word('foot', noun, forms(['feet', 'foot', 'foots']), demand([question_corpus(11), dataset(298)])).
ml_word('foot', verb, forms(['foot', 'footed', 'footing', 'foots']), demand([question_corpus(2), dataset(31)])).
ml_word('football', noun, forms(['football', 'footballs']), demand([dataset(76)])).
ml_word('footstep', noun, forms(['footstep', 'footsteps']), demand([question_corpus(1)])).
ml_word('force', noun, forms(['force', 'forces']), demand([dataset(10)])).
ml_word('force', verb, forms(['force', 'forced', 'forces', 'forcing']), demand([dataset(10)])).
ml_word('forehearth', noun, forms(['forehearth', 'metal']), demand([dataset(3)])).
ml_word('forest', noun, forms(['forest', 'forests']), demand([dataset(10)])).
ml_word('forest', verb, forms(['forest', 'forested', 'foresting', 'forests']), demand([dataset(10)])).
ml_word('forest', adjective, forms(['forest']), demand([dataset(10)])).
ml_word('forget', verb, forms(['forget', 'forgets', 'forgetting', 'forgot', 'forgotten']), demand([dataset(2)])).
ml_word('fork', noun, forms(['fork', 'forks']), demand([question_corpus(3)])).
ml_word('fork', verb, forms(['fork', 'forked', 'forking', 'forks']), demand([question_corpus(3)])).
ml_word('form', verb, forms(['form', 'formed', 'forming', 'forms']), demand([question_corpus(4), dataset(2)])).
ml_word('formed', adjective, forms(['formed']), demand([question_corpus(1)])).
ml_word('former', noun, forms(['former', 'formers']), demand([dataset(2)])).
ml_word('former', adjective, forms(['former']), demand([dataset(2)])).
ml_word('formula', noun, forms(['formula', 'formulas', 'formulæ']), demand([question_corpus(4), dataset(5)])).
ml_word('fort', noun, forms(['fort', 'forts']), demand([question_corpus(1), dataset(7)])).
ml_word('forth', noun, forms(['forth', 'forths']), demand([dataset(7)])).
ml_word('forth', verb, forms(['forth']), demand([dataset(7)])).
ml_word('forth', preposition, forms(['forth']), demand([dataset(7)])).
ml_word('forty', noun, forms(['forties', 'forty']), demand([dataset(6)])).
ml_word('forty', adjective, forms(['forty']), demand([dataset(6)])).
ml_word('forward', noun, forms(['forward', 'forwards']), demand([dataset(47)])).
ml_word('forward', verb, forms(['forward', 'forwarded', 'forwarding', 'forwards']), demand([dataset(47)])).
ml_word('forward', adjective, forms(['forward']), demand([dataset(47)])).
ml_word('forward', adverb, forms(['forward']), demand([dataset(47)])).
ml_word('found', noun, forms(['found', 'founds']), demand([question_corpus(9), dataset(30)])).
ml_word('found', verb, forms(['found', 'founded', 'founding', 'founds']), demand([question_corpus(9), dataset(30)])).
ml_word('foundation', noun, forms(['foundation', 'foundations']), demand([question_corpus(2)])).
ml_word('four', noun, forms(['four', 'fours']), demand([question_corpus(2), dataset(94)])).
ml_word('four', adjective, forms(['four']), demand([question_corpus(2), dataset(94)])).
ml_word('fourth', noun, forms(['fourth', 'fourths']), demand([question_corpus(5), dataset(69)])).
ml_word('fourth', adjective, forms(['fourth']), demand([question_corpus(4), dataset(58)])).
ml_word('frac', math_notation, forms(['frac']), demand([question_corpus(1), supplement_class('math_notation')])).
ml_word('fraction', noun, forms(['fraction', 'fractions']), demand([question_corpus(34), dataset(28), questioning_paper_lexicon])).
ml_word('fraction', verb, forms(['fraction', 'fractioned', 'fractioning', 'fractions']), demand([question_corpus(34), dataset(28), questioning_paper_lexicon])).
ml_word('fracture', noun, forms(['fracture', 'fractures']), demand([dataset(2)])).
ml_word('fracture', verb, forms(['fracture', 'fractured', 'fractures', 'fracturing']), demand([dataset(2)])).
ml_word('frame', noun, forms(['frame', 'frames']), demand([question_corpus(15), questioning_paper_lexicon])).
ml_word('frame', verb, forms(['frame', 'framed', 'frames', 'framing']), demand([question_corpus(15), questioning_paper_lexicon])).
ml_word('francisco', place_name, forms(['francisco']), demand([question_corpus(1), supplement_class('place_name')])).
ml_word('frank', noun, forms(['frank', 'franks']), demand([dataset(94)])).
ml_word('frank', verb, forms(['frank', 'franked', 'franking', 'franks']), demand([dataset(94)])).
ml_word('frank', adjective, forms(['frank']), demand([dataset(94)])).
ml_word('frankie', given_name, forms(['frankie']), demand([dataset(4), supplement_class('given_name')])).
ml_word('fred', noun, forms(['fred', 'freds']), demand([dataset(11)])).
ml_word('free', verb, forms(['free', 'freed', 'freeing', 'frees']), demand([question_corpus(1), dataset(37)])).
ml_word('free', adjective, forms(['free', 'freer', 'freest']), demand([question_corpus(1), dataset(37)])).
ml_word('free', adverb, forms(['free']), demand([question_corpus(1), dataset(37)])).
ml_word('frequency', noun, forms(['frequencies', 'frequency']), demand([question_corpus(1)])).
ml_word('frequent', verb, forms(['frequent', 'frequented', 'frequenting', 'frequents']), demand([dataset(2)])).
ml_word('frequent', adjective, forms(['frequent']), demand([dataset(2)])).
ml_word('fresh', noun, forms(['fresh', 'freshes']), demand([dataset(34)])).
ml_word('fresh', verb, forms(['fresh', 'freshed', 'freshes', 'freshing']), demand([dataset(34)])).
ml_word('fresh', adjective, forms(['fresh', 'fresher', 'freshest']), demand([dataset(34)])).
ml_word('friday', noun, forms(['friday', 'fridays']), demand([dataset(109)])).
ml_word('fridge', verb, forms(['fridge', 'fridged', 'fridges', 'fridging']), demand([dataset(23)])).
ml_word('friend', noun, forms(['friend', 'friends']), demand([question_corpus(4), dataset(293)])).
ml_word('friend', verb, forms(['friend', 'friended', 'friending', 'friends']), demand([question_corpus(4), dataset(293)])).
ml_word('friendship', noun, forms(['friendship', 'friendships']), demand([question_corpus(1)])).
ml_word('frog', noun, forms(['frog', 'frogs']), demand([dataset(56)])).
ml_word('frog', verb, forms(['frog', 'froged', 'froging', 'frogs']), demand([dataset(56)])).
ml_word('front', noun, forms(['front', 'fronts']), demand([dataset(6)])).
ml_word('front', verb, forms(['front', 'fronted', 'fronting', 'fronts']), demand([dataset(6)])).
ml_word('front', adjective, forms(['front']), demand([dataset(6)])).
ml_word('frost', noun, forms(['frost', 'frosts']), demand([dataset(22)])).
ml_word('frost', verb, forms(['frost', 'frosting', 'frosts', 'frostted']), demand([dataset(47)])).
ml_word('frosted', adjective, forms(['frosted']), demand([dataset(2)])).
ml_word('frosting', noun, forms(['frosting', 'frostings']), demand([dataset(25)])).
ml_word('fruit', noun, forms(['fruit', 'fruits']), demand([dataset(10)])).
ml_word('fruit', verb, forms(['fruit', 'fruited', 'fruiting', 'fruits']), demand([dataset(10)])).
ml_word('fry', noun, forms(['fries', 'fry']), demand([dataset(4)])).
ml_word('fry', verb, forms(['fried', 'fries', 'fry', 'frying']), demand([dataset(4)])).
ml_word('ft', unit_abbreviation, forms(['ft']), demand([dataset(54), supplement_class('unit_abbreviation')])).
ml_word('fuel', noun, forms(['fuel', 'fuels']), demand([dataset(19)])).
ml_word('fuel', verb, forms(['fuel', 'fueled', 'fueling', 'fuels']), demand([dataset(19)])).
ml_word('fulfill', verb, forms(['fulfill', 'fulfilled', 'fulfilling', 'fulfills']), demand([dataset(2)])).
ml_word('full', noun, forms(['full', 'fulls']), demand([question_corpus(1), dataset(61)])).
ml_word('full', verb, forms(['full', 'fulled', 'fulling', 'fulls']), demand([question_corpus(1), dataset(61)])).
ml_word('full', adjective, forms(['full', 'fuller', 'fullest']), demand([question_corpus(1), dataset(61)])).
ml_word('full', adverb, forms(['full']), demand([question_corpus(1), dataset(61)])).
ml_word('fully', adverb, forms(['fully']), demand([dataset(10)])).
ml_word('fun', noun, forms(['fun', 'funs']), demand([question_corpus(1)])).
ml_word('function', noun, forms(['function', 'functions']), demand([question_corpus(3), questioning_paper_lexicon])).
ml_word('function', verb, forms(['function', 'functioned', 'functioning', 'functions']), demand([question_corpus(3), questioning_paper_lexicon])).
ml_word('fund', noun, forms(['fund', 'funds']), demand([dataset(5)])).
ml_word('fund', verb, forms(['fund', 'funded', 'funding', 'funds']), demand([dataset(5)])).
ml_word('fundraiser', noun, forms(['fundraiser', 'fundraisers']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('furniture', noun, forms(['furniture', 'furnitures']), demand([question_corpus(1), dataset(3)])).
ml_word('further', verb, forms(['further', 'furthered', 'furthering', 'furthers']), demand([dataset(9)])).
ml_word('further', adjective, forms(['further']), demand([dataset(9)])).
ml_word('further', adverb, forms(['further']), demand([dataset(9)])).
ml_word('future', noun, forms(['future', 'futures']), demand([question_corpus(3), dataset(10)])).
ml_word('future', adjective, forms(['future']), demand([question_corpus(3), dataset(10)])).
ml_word('gain', noun, forms(['gain', 'gains']), demand([question_corpus(1), dataset(4)])).
ml_word('gain', verb, forms(['gain', 'gained', 'gaining', 'gains']), demand([question_corpus(1), dataset(20)])).
ml_word('gain', adjective, forms(['gain']), demand([question_corpus(1), dataset(4)])).
ml_word('gala', noun, forms(['gala', 'galas']), demand([dataset(2)])).
ml_word('gallery', noun, forms(['galleries', 'gallery']), demand([question_corpus(1)])).
ml_word('gallon', noun, forms(['gallon', 'gallons']), demand([question_corpus(1), dataset(215)])).
ml_word('game', noun, forms(['game', 'games']), demand([question_corpus(8), dataset(250)])).
ml_word('game', verb, forms(['game', 'gamed', 'games', 'gaming']), demand([question_corpus(8), dataset(250)])).
ml_word('game', adjective, forms(['game']), demand([question_corpus(6), dataset(109)])).
ml_word('gap', noun, forms(['gap', 'gaps']), demand([question_corpus(1), dataset(2)])).
ml_word('gap', verb, forms(['gap', 'gaped', 'gaping', 'gaps']), demand([question_corpus(1), dataset(2)])).
ml_word('garage', noun, forms(['garage', 'garages']), demand([question_corpus(1), dataset(8)])).
ml_word('garage', verb, forms(['garage', 'garaged', 'garages', 'garaging']), demand([question_corpus(1), dataset(8)])).
ml_word('garbage', verb, forms(['garbage', 'garbaged', 'garbages', 'garbaging']), demand([question_corpus(2)])).
ml_word('garden', noun, forms(['garden', 'gardens']), demand([question_corpus(4), dataset(14)])).
ml_word('garden', verb, forms(['garden', 'gardened', 'gardening', 'gardens']), demand([question_corpus(4), dataset(14)])).
ml_word('gas', noun, forms(['gas', 'gases']), demand([dataset(122)])).
ml_word('gather', noun, forms(['gather', 'gathers']), demand([dataset(10)])).
ml_word('gather', verb, forms(['gather', 'gathered', 'gathering', 'gathers']), demand([dataset(33)])).
ml_word('gathering', noun, forms(['gathering', 'gatherings']), demand([dataset(9)])).
ml_word('gathering', adjective, forms(['gathering']), demand([dataset(9)])).
ml_word('gavin', given_name, forms(['gavin']), demand([dataset(6), supplement_class('given_name')])).
ml_word('gb', unit_abbreviation, forms(['gb']), demand([dataset(70), supplement_class('unit_abbreviation')])).
ml_word('gecko', noun, forms(['gecko', 'geckoes', 'geckos']), demand([dataset(6)])).
ml_word('gemstone', noun, forms(['gemstone', 'gemstones']), demand([dataset(26), supplement_class('common_noun')])).
ml_word('gender', noun, forms(['gender', 'genders']), demand([dataset(15)])).
ml_word('gender', verb, forms(['gender', 'gendered', 'gendering', 'genders']), demand([dataset(15)])).
ml_word('generally', adverb, forms(['generally']), demand([question_corpus(1)])).
ml_word('geoblock', noun, forms(['geoblock', 'geoblocks']), demand([question_corpus(1), supplement_class('math_term')])).
ml_word('geoff', given_name, forms(['geoff']), demand([dataset(8), supplement_class('given_name')])).
ml_word('geography', noun, forms(['geographies', 'geography']), demand([dataset(6)])).
ml_word('geometry', noun, forms(['geometries', 'geometry']), demand([dataset(2), supplement_class('math_term')])).
ml_word('george', noun, forms(['george', 'georges']), demand([dataset(6)])).
ml_word('geranium', noun, forms(['geranium', 'geraniums']), demand([dataset(5)])).
ml_word('german', noun, forms(['german', 'germans', 'germen']), demand([dataset(2)])).
ml_word('german', adjective, forms(['german']), demand([dataset(2)])).
ml_word('germany', place_name, forms(['germany']), demand([dataset(7), supplement_class('place_name')])).
ml_word('get', noun, forms(['get', 'gets']), demand([question_corpus(20), dataset(664)])).
ml_word('get', verb, forms(['get', 'gets', 'getting', 'got', 'gotten']), demand([question_corpus(27), dataset(856), supplement_class('corpus_verb')])).
ml_word('getting', noun, forms(['getting', 'gettings']), demand([question_corpus(5), dataset(21)])).
ml_word('giant', noun, forms(['giant', 'giants']), demand([question_corpus(1), dataset(7)])).
ml_word('giant', adjective, forms(['giant']), demand([question_corpus(1), dataset(4)])).
ml_word('gift', noun, forms(['gift', 'gifts']), demand([question_corpus(2), dataset(85)])).
ml_word('gift', verb, forms(['gift', 'gifted', 'gifting', 'gifts']), demand([question_corpus(2), dataset(85)])).
ml_word('gigabyte', noun, forms(['gigabyte', 'gigabytes']), demand([dataset(5), supplement_class('common_noun')])).
ml_word('gina', given_name, forms(['gina']), demand([dataset(8), supplement_class('given_name')])).
ml_word('girl', noun, forms(['girl', 'girls']), demand([dataset(71)])).
ml_word('girlfriend', noun, forms(['girlfriend', 'girlfriends']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('giselle', given_name, forms(['giselle']), demand([dataset(12), supplement_class('given_name')])).
ml_word('giuliana', given_name, forms(['giuliana']), demand([dataset(3), supplement_class('given_name')])).
ml_word('give', verb, forms(['gave', 'give', 'gived', 'given', 'gives', 'giving']), demand([question_corpus(20), dataset(532)])).
ml_word('gives', noun, forms(['gives']), demand([dataset(134)])).
ml_word('giving', noun, forms(['giving', 'givings']), demand([question_corpus(1), dataset(23)])).
ml_word('glass', noun, forms(['glass', 'glasses']), demand([dataset(113)])).
ml_word('glass', verb, forms(['glass', 'glassed', 'glasses', 'glassing']), demand([dataset(113)])).
ml_word('glee', noun, forms(['glee', 'glees']), demand([dataset(2)])).
ml_word('glenn', given_name, forms(['glenn']), demand([dataset(6), supplement_class('given_name')])).
ml_word('gloria', noun, forms(['gloria', 'glorias']), demand([dataset(6)])).
ml_word('glow', noun, forms(['glow', 'glows']), demand([dataset(5)])).
ml_word('glow', verb, forms(['glow', 'glowed', 'glowing', 'glows']), demand([dataset(5)])).
ml_word('gnome', noun, forms(['gnome', 'gnomes']), demand([dataset(60)])).
ml_word('go', noun, forms(['go', 'gos']), demand([question_corpus(78), dataset(114)])).
ml_word('go', verb, forms(['go', 'goes', 'going', 'gone', 'went']), demand([question_corpus(90), dataset(402)])).
ml_word('goal', noun, forms(['goal', 'goals']), demand([question_corpus(1), dataset(136)])).
ml_word('goat', noun, forms(['goat', 'goats']), demand([dataset(18)])).
ml_word('going', noun, forms(['going', 'goings']), demand([question_corpus(4), dataset(89)])).
ml_word('gold', noun, forms(['gold', 'golds']), demand([dataset(20)])).
ml_word('goldfish', noun, forms(['goldfish', 'goldfishes']), demand([dataset(25)])).
ml_word('golf', noun, forms(['golf', 'golfs']), demand([dataset(30)])).
ml_word('good', noun, forms(['good', 'goods']), demand([question_corpus(8), dataset(24)])).
ml_word('good', verb, forms(['good', 'gooded', 'gooding', 'goods']), demand([question_corpus(8), dataset(24)])).
ml_word('good', adjective, forms(['best', 'better', 'good']), demand([question_corpus(24), dataset(34)])).
ml_word('good', adverb, forms(['good']), demand([question_corpus(7), dataset(14)])).
ml_word('goodie', noun, forms(['goodie', 'goodies']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('goods', noun, forms(['goods']), demand([question_corpus(1), dataset(10)])).
ml_word('goody', noun, forms(['goodies', 'goody']), demand([dataset(4)])).
ml_word('gourmet', noun, forms(['gourmet', 'gourmets']), demand([dataset(8)])).
ml_word('governor', noun, forms(['governor', 'governors']), demand([dataset(38)])).
ml_word('grab', noun, forms(['grab', 'grabs']), demand([dataset(24)])).
ml_word('grab', verb, forms(['grab', 'grabbed', 'grabbing', 'grabs']), demand([dataset(26)])).
ml_word('grade', noun, forms(['grade', 'grades']), demand([question_corpus(2), dataset(26)])).
ml_word('grade', verb, forms(['grade', 'graded', 'grades', 'grading']), demand([question_corpus(2), dataset(26)])).
ml_word('grader', noun, forms(['grader', 'graders']), demand([question_corpus(1)])).
ml_word('graham', adjective, forms(['graham']), demand([dataset(10), supplement_class('adjective')])).
ml_word('gram', noun, forms(['gram', 'grams']), demand([dataset(11)])).
ml_word('grandchild', noun, forms(['grandchild', 'grandchildren', 'grandchilds']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('grandma', noun, forms(['grandma', 'grandmas']), demand([dataset(2)])).
ml_word('granville', place_name, forms(['granville']), demand([dataset(7), supplement_class('place_name')])).
ml_word('grape', noun, forms(['grape', 'grapes']), demand([dataset(8)])).
ml_word('graph', noun, forms(['graph', 'graphs']), demand([question_corpus(28), supplement_class('common_noun'), supplement_class('math_term')])).
ml_word('graph', verb, forms(['graph', 'graphed', 'graphing', 'graphs']), demand([question_corpus(29), supplement_class('corpus_verb')])).
ml_word('grass', noun, forms(['grass', 'grasses']), demand([dataset(22)])).
ml_word('grass', verb, forms(['grass', 'grassed', 'grasses', 'grassing']), demand([dataset(22)])).
ml_word('gratuity', noun, forms(['gratuities', 'gratuity', 'gtratuities']), demand([dataset(11)])).
ml_word('gray', noun, forms(['gray', 'grays']), demand([question_corpus(2)])).
ml_word('gray', adjective, forms(['gray', 'grayer', 'grayest']), demand([question_corpus(2)])).
ml_word('grayson', family_name, forms(['grayson']), demand([dataset(7), supplement_class('family_name')])).
ml_word('great', adjective, forms(['great', 'greater', 'greatest']), demand([question_corpus(15), dataset(8)])).
ml_word('green', verb, forms(['green', 'greened', 'greening', 'greens']), demand([question_corpus(4), dataset(66)])).
ml_word('green', adjective, forms(['green', 'greener', 'greenest']), demand([question_corpus(4), dataset(66)])).
ml_word('gremlins', named_entity, forms(['gremlins']), demand([dataset(4), supplement_class('named_entity')])).
ml_word('grid', noun, forms(['grid', 'grids']), demand([question_corpus(6)])).
ml_word('grind', verb, forms(['grind', 'grinded', 'grinding', 'grinds', 'ground']), demand([dataset(17)])).
ml_word('grocery', noun, forms(['groceries', 'grocery']), demand([question_corpus(1), dataset(27)])).
ml_word('gross', noun, forms(['gross', 'grosses']), demand([dataset(12)])).
ml_word('gross', adjective, forms(['gross', 'grosser', 'grossest']), demand([dataset(12)])).
ml_word('ground', noun, forms(['ground', 'grounds']), demand([dataset(17)])).
ml_word('ground', verb, forms(['ground', 'grounded', 'grounding', 'grounds']), demand([dataset(17)])).
ml_word('group', noun, forms(['group', 'groups']), demand([question_corpus(46), dataset(76)])).
ml_word('group', verb, forms(['group', 'grouped', 'grouping', 'groups']), demand([question_corpus(47), dataset(76)])).
ml_word('grouping', noun, forms(['grouping', 'groupings']), demand([question_corpus(1)])).
ml_word('grow', verb, forms(['grew', 'grow', 'growed', 'growing', 'grown', 'grows']), demand([question_corpus(6), dataset(18)])).
ml_word('growth', noun, forms(['growth', 'growths']), demand([question_corpus(1), dataset(2)])).
ml_word('guarantee', verb, forms(['guarantee', 'guaranteed', 'guaranteeing', 'guarantees']), demand([dataset(10)])).
ml_word('guess', noun, forms(['guess', 'guesses']), demand([question_corpus(1)])).
ml_word('guess', verb, forms(['guess', 'guessed', 'guesses', 'guessing']), demand([question_corpus(1)])).
ml_word('guest', noun, forms(['guest', 'guests']), demand([dataset(123)])).
ml_word('guest', verb, forms(['guest', 'guested', 'guesting', 'guests']), demand([dataset(123)])).
ml_word('guideline', noun, forms(['guideline', 'guidelines']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('guilty', adjective, forms(['guiltiest', 'guilty', 'gultier']), demand([dataset(2)])).
ml_word('gumball', noun, forms(['gumball', 'gumballs']), demand([dataset(41), supplement_class('common_noun')])).
ml_word('gummy', adjective, forms(['gummer', 'gummirst', 'gummy']), demand([dataset(25)])).
ml_word('gunner', noun, forms(['gunner', 'gunners']), demand([dataset(5)])).
ml_word('gym', noun, forms(['gym', 'gyms']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('h', algebra_symbol, forms(['h']), demand([dataset(5), supplement_class('algebra_symbol')])).
ml_word('hair', noun, forms(['hair', 'hairs']), demand([dataset(20)])).
ml_word('haircut', noun, forms(['haircut', 'haircuts']), demand([dataset(58), supplement_class('common_noun')])).
ml_word('half', noun, forms(['half', 'halves']), demand([question_corpus(5), dataset(522)])).
ml_word('half', verb, forms(['half', 'halfed', 'halfing', 'halves']), demand([question_corpus(5), dataset(522)])).
ml_word('half', adjective, forms(['half']), demand([question_corpus(4), dataset(516)])).
ml_word('half', adverb, forms(['half']), demand([question_corpus(4), dataset(516)])).
ml_word('halfway', adjective, forms(['halfway']), demand([dataset(3)])).
ml_word('halfway', adverb, forms(['halfway']), demand([dataset(3)])).
ml_word('halloween', noun, forms(['halloween', 'halloweens']), demand([dataset(4)])).
ml_word('halve', noun, forms(['halve', 'halves']), demand([question_corpus(1), dataset(7)])).
ml_word('halve', verb, forms(['halve', 'halved', 'halves', 'halving']), demand([question_corpus(2), dataset(7)])).
ml_word('halved', adjective, forms(['halved']), demand([question_corpus(1)])).
ml_word('halves', noun, forms(['halves', 'halveses']), demand([question_corpus(1), dataset(6)])).
ml_word('hamburger', noun, forms(['hamburger', 'hamburgers']), demand([dataset(42), supplement_class('common_noun')])).
ml_word('hamza', given_name, forms(['hamza']), demand([dataset(3), supplement_class('given_name')])).
ml_word('han', given_name, forms(['han']), demand([question_corpus(9), supplement_class('given_name')])).
ml_word('hand', noun, forms(['hand', 'hands']), demand([question_corpus(3), dataset(24)])).
ml_word('hand', verb, forms(['hand', 'handed', 'handing', 'hands']), demand([question_corpus(3), dataset(24)])).
ml_word('handful', noun, forms(['handful', 'handfuls']), demand([dataset(8)])).
ml_word('handle', noun, forms(['handle', 'handles']), demand([dataset(2)])).
ml_word('handle', verb, forms(['handle', 'handled', 'handles', 'handling']), demand([dataset(2)])).
ml_word('hang', verb, forms(['hang', 'hanged', 'hanging', 'hangs', 'hung']), demand([dataset(3), supplement_class('corpus_verb')])).
ml_word('hanger', noun, forms(['hanger', 'hangers']), demand([question_corpus(2)])).
ml_word('hanging', noun, forms(['hanging', 'hangings']), demand([dataset(2)])).
ml_word('hanging', adjective, forms(['hanging']), demand([dataset(2)])).
ml_word('hank', noun, forms(['hank', 'hanks']), demand([dataset(5)])).
ml_word('hank', verb, forms(['hank', 'hanked', 'hanking', 'hanks']), demand([dataset(5)])).
ml_word('hanna', given_name, forms(['hanna']), demand([dataset(12), supplement_class('given_name')])).
ml_word('hansel', noun, forms(['hansel', 'hansels']), demand([dataset(6)])).
ml_word('hansel', verb, forms(['hansel']), demand([dataset(6)])).
ml_word('happen', verb, forms(['happen', 'happened', 'happening', 'happens']), demand([question_corpus(19), dataset(9)])).
ml_word('happy', adjective, forms(['happier', 'happiest', 'happy']), demand([dataset(12)])).
ml_word('hard', noun, forms(['hard', 'hards']), demand([question_corpus(1), dataset(6)])).
ml_word('hard', verb, forms(['hard', 'harded', 'harding', 'hards']), demand([question_corpus(1), dataset(6)])).
ml_word('hard', adjective, forms(['hard', 'harder', 'hardest']), demand([question_corpus(2), dataset(6)])).
ml_word('hard', adverb, forms(['hard']), demand([question_corpus(1), dataset(6)])).
ml_word('hardcover', noun, forms(['hardcover', 'hardcovers']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('harder', noun, forms(['harder', 'harders']), demand([question_corpus(1)])).
ml_word('hardware', noun, forms(['hardware', 'hardwares']), demand([question_corpus(1)])).
ml_word('hare', noun, forms(['hare', 'hares']), demand([dataset(21)])).
ml_word('hare', verb, forms(['hare', 'hared', 'hares', 'haring']), demand([dataset(21)])).
ml_word('harold', given_name, forms(['harold']), demand([dataset(3), supplement_class('given_name')])).
ml_word('harry', verb, forms(['harried', 'harries', 'harry', 'harrying']), demand([dataset(31)])).
ml_word('harsh', adjective, forms(['harsh', 'harsher', 'harshest']), demand([dataset(2)])).
ml_word('harvest', noun, forms(['harvest', 'harvests']), demand([dataset(57)])).
ml_word('harvest', verb, forms(['harvest', 'harvested', 'harvesting', 'harvests']), demand([dataset(63)])).
ml_word('harvesting', noun, forms(['harvesting', 'harvestings']), demand([dataset(2)])).
ml_word('harvesting', adjective, forms(['harvesting']), demand([dataset(2)])).
ml_word('hat', noun, forms(['hat', 'hats']), demand([dataset(76)])).
ml_word('hatch', noun, forms(['hatch', 'hatches']), demand([dataset(10)])).
ml_word('hatch', verb, forms(['hatch', 'hatched', 'hatches', 'hatching']), demand([dataset(28)])).
ml_word('hatching', noun, forms(['hatching', 'hatchings']), demand([dataset(8)])).
ml_word('have', verb, forms(['had', 'has', 'have', 'having']), demand([question_corpus(171), dataset(3224)])).
ml_word('having', noun, forms(['having', 'havings']), demand([question_corpus(2), dataset(40)])).
ml_word('hawaii', place_name, forms(['hawaii']), demand([dataset(3), supplement_class('place_name')])).
ml_word('hawkins', family_name, forms(['hawkins']), demand([dataset(10), supplement_class('family_name')])).
ml_word('hawksbill', noun, forms(['hawksbill', 'hawksbills']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('hay', noun, forms(['hay', 'hays']), demand([dataset(14)])).
ml_word('hay', verb, forms(['hay', 'hayed', 'haying', 'hays']), demand([dataset(14)])).
ml_word('hayden', given_name, forms(['hayden']), demand([dataset(7), supplement_class('given_name')])).
ml_word('hayes', given_name, forms(['hayes']), demand([dataset(2), supplement_class('given_name')])).
ml_word('he', pronoun, forms(['he']), demand([question_corpus(7), dataset(2836)])).
ml_word('head', noun, forms(['head', 'heads']), demand([dataset(19)])).
ml_word('head', verb, forms(['head', 'headed', 'heading', 'heads']), demand([dataset(27)])).
ml_word('head', adjective, forms(['head']), demand([dataset(14)])).
ml_word('headed', adjective, forms(['headed']), demand([dataset(8)])).
ml_word('headphone', noun, forms(['headphone', 'headphones']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('heal', noun, forms(['heal', 'heals']), demand([dataset(6)])).
ml_word('heal', verb, forms(['heal', 'healed', 'healing', 'heals']), demand([dataset(8)])).
ml_word('healthy', adjective, forms(['healthier', 'healthiest', 'healthy']), demand([dataset(19)])).
ml_word('hear', verb, forms(['hear', 'heard', 'hearing', 'hears']), demand([question_corpus(7)])).
ml_word('heavy', verb, forms(['heavies', 'heavy', 'heavyed', 'heavying']), demand([question_corpus(1), dataset(14)])).
ml_word('heavy', adjective, forms(['heavier', 'heaviest', 'heavy']), demand([question_corpus(1), dataset(29)])).
ml_word('hector', noun, forms(['hector', 'hectors']), demand([dataset(14)])).
ml_word('hector', verb, forms(['hector', 'hectored', 'hectoring', 'hectors']), demand([dataset(14)])).
ml_word('heel', noun, forms(['heel', 'heels']), demand([dataset(30)])).
ml_word('heel', verb, forms(['heel', 'heeled', 'heeling', 'heels']), demand([dataset(30)])).
ml_word('height', noun, forms(['height', 'heights']), demand([question_corpus(14), dataset(21)])).
ml_word('helicoid', noun, forms(['helicoid', 'helicoids']), demand([webster_domain('geom')])).
ml_word('helicoid', adjective, forms(['helicoid']), demand([webster_domain('geom')])).
ml_word('helium', noun, forms(['helium', 'heliums']), demand([dataset(12)])).
ml_word('help', noun, forms(['help', 'helps']), demand([question_corpus(114), dataset(32)])).
ml_word('help', verb, forms(['help', 'helped', 'helping', 'helps', 'holp']), demand([question_corpus(127), dataset(32)])).
ml_word('helpful', adjective, forms(['helpful']), demand([question_corpus(22)])).
ml_word('hen', noun, forms(['hen', 'hens']), demand([dataset(5)])).
ml_word('hence', verb, forms(['hence', 'henced', 'hences', 'hencing']), demand([dataset(18)])).
ml_word('hence', adverb, forms(['hence']), demand([dataset(18)])).
ml_word('henry', noun, forms(['henries', 'henry', 'henrys']), demand([dataset(20)])).
ml_word('her', adjective, forms(['her']), demand([question_corpus(2), dataset(1403)])).
ml_word('her', pronoun, forms(['her']), demand([question_corpus(2), dataset(1403)])).
ml_word('hers', pronoun, forms(['hers']), demand([dataset(1)])).
ml_word('herself', pronoun, forms(['herself']), demand([dataset(40)])).
ml_word('hexagon', noun, forms(['hexagon', 'hexagons']), demand([question_corpus(1)])).
ml_word('hidden', adjective, forms(['hidden']), demand([question_corpus(1)])).
ml_word('hide', verb, forms(['hid', 'hidden', 'hide', 'hided', 'hides', 'hiding']), demand([question_corpus(1), dataset(18)])).
ml_word('hiding', noun, forms(['hiding', 'hidings']), demand([dataset(16)])).
ml_word('high', noun, forms(['high', 'highs']), demand([question_corpus(56), dataset(41)])).
ml_word('high', verb, forms(['high', 'highed', 'highing', 'highs']), demand([question_corpus(56), dataset(41)])).
ml_word('high', adjective, forms(['high', 'higher', 'highest']), demand([question_corpus(57), dataset(57)])).
ml_word('high', adverb, forms(['high']), demand([question_corpus(56), dataset(41)])).
ml_word('highlight', verb, forms(['highlight', 'highlighted', 'highlighting', 'highlights']), demand([question_corpus(2), supplement_class('corpus_verb')])).
ml_word('hiker', noun, forms(['hiker', 'hikers']), demand([question_corpus(1), supplement_class('common_noun')])).
ml_word('hilary', given_name, forms(['hilary']), demand([dataset(4), supplement_class('given_name')])).
ml_word('hill', noun, forms(['hill', 'hills']), demand([dataset(61)])).
ml_word('hill', verb, forms(['hill', 'hilled', 'hilling', 'hills']), demand([dataset(61)])).
ml_word('hillary', given_name, forms(['hillary']), demand([dataset(8), supplement_class('given_name')])).
ml_word('him', pronoun, forms(['him']), demand([dataset(181)])).
ml_word('himself', pronoun, forms(['himself']), demand([dataset(20)])).
ml_word('hire', noun, forms(['hire', 'hires']), demand([dataset(2)])).
ml_word('hire', verb, forms(['hire', 'hired', 'hires', 'hiring']), demand([dataset(7)])).
ml_word('hire', pronoun, forms(['hire']), demand([dataset(2)])).
ml_word('his', pronoun, forms(['his']), demand([question_corpus(4), dataset(1284)])).
ml_word('histogram', noun, forms(['histogram', 'histograms']), demand([question_corpus(2), supplement_class('math_term')])).
ml_word('history', noun, forms(['histories', 'history']), demand([dataset(6)])).
ml_word('history', verb, forms(['historied', 'histories', 'history', 'historying']), demand([dataset(6)])).
ml_word('hit', noun, forms(['hit', 'hits']), demand([dataset(8)])).
ml_word('hit', verb, forms(['hit', 'hited', 'hiting', 'hits', 'hitting']), demand([dataset(8)])).
ml_word('hit', pronoun, forms(['hit']), demand([dataset(8)])).
ml_word('hoard', noun, forms(['hoard', 'hoards']), demand([dataset(5)])).
ml_word('hoard', verb, forms(['hoard', 'hoarded', 'hoarding', 'hoards']), demand([dataset(5)])).
ml_word('hobby', noun, forms(['hobbies', 'hobby']), demand([dataset(4)])).
ml_word('hold', noun, forms(['hold', 'holds']), demand([question_corpus(3), dataset(102)])).
ml_word('hold', verb, forms(['held', 'hold', 'holding', 'holds']), demand([question_corpus(8), dataset(111)])).
ml_word('holding', noun, forms(['holding', 'holdings']), demand([question_corpus(5), dataset(3)])).
ml_word('hole', noun, forms(['hole', 'holes']), demand([dataset(2)])).
ml_word('hole', verb, forms(['hole', 'holed', 'holes', 'holing']), demand([dataset(2)])).
ml_word('hole', adjective, forms(['hole']), demand([dataset(2)])).
ml_word('holiday', noun, forms(['holiday', 'holidays']), demand([dataset(2)])).
ml_word('holiday', adjective, forms(['holiday']), demand([dataset(2)])).
ml_word('home', noun, forms(['home', 'homes']), demand([question_corpus(2), dataset(99)])).
ml_word('home', adjective, forms(['home']), demand([question_corpus(2), dataset(94)])).
ml_word('home', adverb, forms(['home']), demand([question_corpus(2), dataset(94)])).
ml_word('homemade', adjective, forms(['homemade']), demand([dataset(10)])).
ml_word('homework', noun, forms(['homework']), demand([question_corpus(2), dataset(36), supplement_class('common_noun')])).
ml_word('hood', noun, forms(['hood', 'hoods']), demand([dataset(4)])).
ml_word('hood', verb, forms(['hood', 'hooded', 'hooding', 'hoods']), demand([dataset(4)])).
ml_word('horizontal', adjective, forms(['horizontal']), demand([question_corpus(1), dataset(18)])).
ml_word('hortense', given_name, forms(['hortense']), demand([dataset(12), supplement_class('given_name')])).
ml_word('hose', noun, forms(['hose', 'hosen', 'hoses']), demand([dataset(2)])).
ml_word('hospital', noun, forms(['hospital', 'hospitals']), demand([dataset(17)])).
ml_word('hospital', adjective, forms(['hospital']), demand([dataset(17)])).
ml_word('host', noun, forms(['host', 'hosts']), demand([dataset(4)])).
ml_word('host', verb, forms(['host', 'hosted', 'hosting', 'hosts']), demand([dataset(8)])).
ml_word('hosting', noun, forms(['hosting', 'hostings']), demand([dataset(4)])).
ml_word('hot', adjective, forms(['hot', 'hotter', 'hottest']), demand([dataset(29)])).
ml_word('hotdog', noun, forms(['hotdog', 'hotdogs']), demand([dataset(85), supplement_class('common_noun')])).
ml_word('hour', noun, forms(['hour', 'hours']), demand([question_corpus(7), dataset(867)])).
ml_word('hourly', adjective, forms(['hourly']), demand([dataset(5)])).
ml_word('hourly', adverb, forms(['hourly']), demand([dataset(5)])).
ml_word('hours', noun, forms(['hours']), demand([question_corpus(4), dataset(644)])).
ml_word('house', noun, forms(['house', 'houses']), demand([question_corpus(2), dataset(342)])).
ml_word('house', verb, forms(['house', 'housed', 'houses', 'housing']), demand([question_corpus(2), dataset(342)])).
ml_word('household', noun, forms(['household', 'households']), demand([dataset(22)])).
ml_word('household', adjective, forms(['household']), demand([dataset(22)])).
ml_word('however', adverb, forms(['however']), demand([dataset(65)])).
ml_word('however', conjunction, forms(['however']), demand([dataset(65)])).
ml_word('hs', algebra_symbol, forms(['hs']), demand([question_corpus(1), supplement_class('algebra_symbol')])).
ml_word('human', noun, forms(['human', 'humans']), demand([question_corpus(1)])).
ml_word('hundred', noun, forms(['hundred', 'hundreds']), demand([question_corpus(3), questioning_paper_lexicon])).
ml_word('hundred', adjective, forms(['hundred']), demand([question_corpus(2)])).
ml_word('hundredth', noun, forms(['hundredth', 'hundredths']), demand([question_corpus(4), dataset(1)])).
ml_word('hundredth', adjective, forms(['hundredth']), demand([dataset(1)])).
ml_word('hungry', adjective, forms(['hungrier', 'hungriest', 'hungry']), demand([dataset(2)])).
ml_word('hunt', noun, forms(['hunt', 'hunts']), demand([dataset(5)])).
ml_word('hunt', verb, forms(['hunt', 'hunted', 'hunting', 'hunts']), demand([dataset(7)])).
ml_word('hunter', noun, forms(['hunter', 'hunters']), demand([dataset(4)])).
ml_word('hunting', noun, forms(['hunting', 'huntings']), demand([dataset(2)])).
ml_word('hurt', noun, forms(['hurt', 'hurts']), demand([dataset(4)])).
ml_word('hurt', verb, forms(['hurt', 'hurting', 'hurts']), demand([dataset(4)])).
ml_word('husband', noun, forms(['husband', 'husbands']), demand([dataset(67)])).
ml_word('husband', verb, forms(['husband', 'husbanded', 'husbanding', 'husbands']), demand([dataset(67)])).
ml_word('hush', noun, forms(['hush', 'hushes']), demand([dataset(16)])).
ml_word('hush', verb, forms(['hush', 'hushed', 'hushes', 'hushing']), demand([dataset(20)])).
ml_word('hush', adjective, forms(['hush']), demand([dataset(12)])).
ml_word('hydrate', verb, forms(['hydrate', 'hydrated', 'hydrates', 'hydrating']), demand([dataset(4)])).
ml_word('hydrated', adjective, forms(['hydrated']), demand([dataset(4)])).
ml_word('hypotenuse', noun, forms(['hypotenuse', 'hypotenuses']), demand([question_corpus(2)])).
ml_word('ice', noun, forms(['ice', 'ices']), demand([dataset(89)])).
ml_word('ice', verb, forms(['ice', 'iced', 'ices', 'icing']), demand([dataset(89)])).
ml_word('idea', noun, forms(['idea', 'ideas']), demand([question_corpus(13), dataset(5)])).
ml_word('identical', adjective, forms(['identical']), demand([question_corpus(1), dataset(3)])).
ml_word('identify', verb, forms(['identified', 'identifies', 'identify', 'identifying']), demand([question_corpus(2), dataset(6)])).
ml_word('ignatius', given_name, forms(['ignatius']), demand([dataset(24), supplement_class('given_name')])).
ml_word('ignore', verb, forms(['ignore', 'ignored', 'ignores', 'ignoring']), demand([dataset(1)])).
ml_word('ill', noun, forms(['ill', 'ills']), demand([dataset(1)])).
ml_word('ill', adjective, forms(['ill']), demand([dataset(1)])).
ml_word('ill', adverb, forms(['ill']), demand([dataset(1)])).
ml_word('illegally', adverb, forms(['illegally']), demand([dataset(2)])).
ml_word('image', noun, forms(['image', 'images']), demand([question_corpus(49)])).
ml_word('image', verb, forms(['image', 'imaged', 'images', 'imaging']), demand([question_corpus(49)])).
ml_word('imaginary', noun, forms(['imaginaries', 'imaginary']), demand([webster_domain('alg')])).
ml_word('imaginary', adjective, forms(['imaginary']), demand([webster_domain('alg')])).
ml_word('immediately', adverb, forms(['immediately']), demand([dataset(7)])).
ml_word('impact', noun, forms(['impact', 'impacts']), demand([question_corpus(5)])).
ml_word('impact', verb, forms(['impact', 'impacted', 'impacting', 'impacts']), demand([question_corpus(5)])).
ml_word('implement', noun, forms(['implement', 'implements']), demand([question_corpus(1)])).
ml_word('implement', verb, forms(['implement', 'implemented', 'implementing', 'implements']), demand([question_corpus(1)])).
ml_word('important', adjective, forms(['important']), demand([question_corpus(14)])).
ml_word('impose', verb, forms(['impose', 'imposed', 'imposes', 'imposing']), demand([dataset(2)])).
ml_word('impossible', noun, forms(['impossible', 'impossibles']), demand([question_corpus(1), dataset(3)])).
ml_word('impossible', adjective, forms(['impossible']), demand([question_corpus(1), dataset(3)])).
ml_word('impress', noun, forms(['impress', 'impresses']), demand([dataset(4)])).
ml_word('impress', verb, forms(['impress', 'impressed', 'impresses', 'impressing']), demand([dataset(4)])).
ml_word('improve', verb, forms(['improve', 'improved', 'improves', 'improving']), demand([question_corpus(5)])).
ml_word('improvement', noun, forms(['improvement', 'improvements']), demand([dataset(6)])).
ml_word('inbox', noun, forms(['inbox', 'inboxes']), demand([dataset(7), supplement_class('common_noun')])).
ml_word('incenter', noun, forms(['incenter', 'incenters']), demand([webster_domain('geom')])).
ml_word('inch', noun, forms(['inch', 'inches']), demand([question_corpus(6), dataset(56)])).
ml_word('inch', verb, forms(['inch', 'inched', 'inches', 'inching']), demand([question_corpus(6), dataset(56)])).
ml_word('inch', adjective, forms(['inch']), demand([question_corpus(1)])).
ml_word('include', verb, forms(['include', 'included', 'includes', 'including']), demand([question_corpus(9), dataset(46)])).
ml_word('included', adjective, forms(['included']), demand([question_corpus(1)])).
ml_word('income', noun, forms(['income', 'incomes']), demand([dataset(4)])).
ml_word('incomplete', adjective, forms(['incomplete']), demand([question_corpus(5)])).
ml_word('incorporate', verb, forms(['incorporate', 'incorporated', 'incorporates', 'incorporating']), demand([question_corpus(1)])).
ml_word('incorporate', adjective, forms(['incorporate']), demand([question_corpus(1)])).
ml_word('incorrect', adjective, forms(['incorrect']), demand([question_corpus(5), dataset(1)])).
ml_word('incorrectly', adverb, forms(['incorrectly']), demand([question_corpus(1)])).
ml_word('increase', noun, forms(['increase', 'increases']), demand([question_corpus(5), dataset(63)])).
ml_word('increase', verb, forms(['increase', 'increased', 'increases', 'increasing']), demand([question_corpus(6), dataset(118)])).
ml_word('increasingly', adverb, forms(['increasingly']), demand([question_corpus(1)])).
ml_word('independent', noun, forms(['independent', 'independents']), demand([question_corpus(2)])).
ml_word('independent', adjective, forms(['independent']), demand([question_corpus(2)])).
ml_word('indicate', verb, forms(['indicate', 'indicated', 'indicates', 'indicating']), demand([question_corpus(1), dataset(5)])).
ml_word('indicated', adjective, forms(['indicated']), demand([question_corpus(1)])).
ml_word('individual', noun, forms(['individual', 'individuals']), demand([question_corpus(1), dataset(13)])).
ml_word('individual', adjective, forms(['individual']), demand([dataset(13)])).
ml_word('individually', adverb, forms(['individually']), demand([dataset(2)])).
ml_word('inequality', noun, forms(['inequalities', 'inequality']), demand([question_corpus(3), questioning_paper_lexicon])).
ml_word('inequation', noun, forms(['inequation', 'inequations']), demand([webster_domain('math')])).
ml_word('infect', verb, forms(['infect', 'infected', 'infecting', 'infects']), demand([dataset(17)])).
ml_word('infest', verb, forms(['infest', 'infested', 'infesting', 'infests']), demand([dataset(4)])).
ml_word('infinitesimal', noun, forms(['infinitesimal', 'infinitesimals']), demand([webster_domain('math')])).
ml_word('infinitesimal', adjective, forms(['infinitesimal']), demand([webster_domain('math')])).
ml_word('inflatable', adjective, forms(['inflatable']), demand([dataset(2)])).
ml_word('inflate', verb, forms(['inflate', 'inflated', 'inflates', 'inflating']), demand([dataset(4)])).
ml_word('inflated', adjective, forms(['inflated']), demand([dataset(4)])).
ml_word('influence', noun, forms(['influence', 'influences']), demand([question_corpus(2)])).
ml_word('influence', verb, forms(['influence', 'influenced', 'influences', 'influencing']), demand([question_corpus(2)])).
ml_word('influencer', noun, forms(['influencer', 'influencers']), demand([dataset(2)])).
ml_word('inform', verb, forms(['inform', 'informed', 'informing', 'informs']), demand([question_corpus(1)])).
ml_word('information', noun, forms(['information', 'informations']), demand([question_corpus(16), dataset(8)])).
ml_word('ingredient', noun, forms(['ingredient', 'ingredients']), demand([dataset(13)])).
ml_word('ingrid', given_name, forms(['ingrid']), demand([dataset(10), supplement_class('given_name')])).
ml_word('initial', noun, forms(['initial', 'initials']), demand([dataset(22)])).
ml_word('initial', verb, forms(['initial', 'initialed', 'initialing', 'initials']), demand([dataset(22)])).
ml_word('initial', adjective, forms(['initial']), demand([dataset(22)])).
ml_word('initially', adverb, forms(['initially']), demand([question_corpus(1), dataset(29)])).
ml_word('injure', verb, forms(['injure', 'injured', 'injures', 'injuring']), demand([dataset(8)])).
ml_word('injury', noun, forms(['injuries', 'injury']), demand([dataset(8)])).
ml_word('input', noun, forms(['input', 'inputs']), demand([question_corpus(2), supplement_class('math_term')])).
ml_word('insect', noun, forms(['insect', 'insects']), demand([question_corpus(1), dataset(3)])).
ml_word('inside', noun, forms(['inside', 'insides']), demand([question_corpus(1), dataset(53)])).
ml_word('inside', preposition, forms(['inside']), demand([question_corpus(1), dataset(53)])).
ml_word('insight', noun, forms(['insight', 'insights']), demand([question_corpus(1)])).
ml_word('instagram', named_entity, forms(['instagram']), demand([dataset(2), supplement_class('named_entity')])).
ml_word('install', verb, forms(['install', 'installed', 'installing', 'installs']), demand([dataset(10)])).
ml_word('instance', noun, forms(['instance', 'instances']), demand([question_corpus(1)])).
ml_word('instance', verb, forms(['instance', 'instanced', 'instances', 'instancing']), demand([question_corpus(1)])).
ml_word('instant', noun, forms(['instant', 'instants']), demand([question_corpus(1)])).
ml_word('instant', adjective, forms(['instant']), demand([question_corpus(1)])).
ml_word('instant', adverb, forms(['instant']), demand([question_corpus(1)])).
ml_word('instead', adverb, forms(['instead']), demand([question_corpus(6), dataset(41)])).
ml_word('instructor', noun, forms(['instructor', 'instructors']), demand([dataset(10)])).
ml_word('insurance', noun, forms(['insurance', 'insurances']), demand([dataset(13)])).
ml_word('integer', noun, forms(['integer', 'integers']), demand([question_corpus(1), questioning_paper_lexicon])).
ml_word('integrability', noun, forms(['integrabilities', 'integrability']), demand([webster_domain('math')])).
ml_word('intend', verb, forms(['intend', 'intended', 'intending', 'intends']), demand([dataset(16)])).
ml_word('intended', noun, forms(['intended', 'intendeds']), demand([dataset(16)])).
ml_word('intended', adjective, forms(['intended']), demand([dataset(16)])).
ml_word('intercept', noun, forms(['intercept', 'intercepts']), demand([questioning_paper_lexicon, webster_domain('math')])).
ml_word('intercept', verb, forms(['intercept', 'intercepted', 'intercepting', 'intercepts']), demand([questioning_paper_lexicon, webster_domain('math')])).
ml_word('interest', noun, forms(['interest', 'interests']), demand([dataset(35)])).
ml_word('interest', verb, forms(['interest', 'interested', 'interesting', 'interests']), demand([question_corpus(1), dataset(35)])).
ml_word('interested', adjective, forms(['interested']), demand([question_corpus(1)])).
ml_word('interpret', verb, forms(['interpret', 'interpreted', 'interpreting', 'interprets']), demand([question_corpus(1)])).
ml_word('interval', noun, forms(['interval', 'intervals']), demand([question_corpus(1), dataset(2)])).
ml_word('interview', noun, forms(['interview', 'interviews']), demand([dataset(21)])).
ml_word('interview', verb, forms(['interview', 'interviewed', 'interviewing', 'interviews']), demand([dataset(24)])).
ml_word('invariable', noun, forms(['invariable', 'invariables']), demand([webster_domain('math')])).
ml_word('invariable', adjective, forms(['invariable']), demand([webster_domain('math')])).
ml_word('invariance', noun, forms(['invariance', 'invariances']), demand([webster_domain('math')])).
ml_word('invariant', noun, forms(['invariant', 'invariants']), demand([webster_domain('math')])).
ml_word('invention', noun, forms(['invention', 'inventions']), demand([dataset(2)])).
ml_word('inventory', noun, forms(['inventories', 'inventory']), demand([question_corpus(1), dataset(2)])).
ml_word('inventory', verb, forms(['inventoried', 'inventories', 'inventory', 'inventorying']), demand([question_corpus(1), dataset(2)])).
ml_word('inverse', noun, forms(['inverse', 'inverses']), demand([dataset(1)])).
ml_word('inverse', adjective, forms(['inverse']), demand([dataset(1)])).
ml_word('invest', verb, forms(['invest', 'invested', 'investing', 'invests']), demand([dataset(2)])).
ml_word('investment', noun, forms(['investment', 'investments']), demand([dataset(10)])).
ml_word('invite', verb, forms(['invite', 'invited', 'invites', 'inviting']), demand([dataset(56)])).
ml_word('involute', noun, forms(['involute', 'involutes']), demand([webster_domain('geom')])).
ml_word('involute', adjective, forms(['involute']), demand([webster_domain('geom')])).
ml_word('involve', verb, forms(['involve', 'involved', 'involves', 'involving']), demand([question_corpus(3), dataset(21)])).
ml_word('involved', adjective, forms(['involved']), demand([question_corpus(1), dataset(20)])).
ml_word('iphone', named_entity, forms(['iphone']), demand([dataset(4), supplement_class('named_entity')])).
ml_word('iqr', noun, forms(['iqr', 'iqrs']), demand([question_corpus(1), supplement_class('math_term')])).
ml_word('iqr', math_notation, forms(['iqr']), demand([question_corpus(1), supplement_class('math_notation')])).
ml_word('iron', noun, forms(['iron', 'irons']), demand([dataset(4)])).
ml_word('iron', verb, forms(['iron', 'ironed', 'ironing', 'irons']), demand([dataset(4)])).
ml_word('iron', adjective, forms(['iron']), demand([dataset(4)])).
ml_word('irrational', adjective, forms(['irrational']), demand([question_corpus(1)])).
ml_word('isabel', noun, forms(['isabel', 'isabels']), demand([dataset(6)])).
ml_word('island', noun, forms(['island', 'islands']), demand([dataset(12)])).
ml_word('island', verb, forms(['island', 'islanded', 'islanding', 'islands']), demand([dataset(12)])).
ml_word('isoperimetry', noun, forms(['isoperimetries', 'isoperimetry']), demand([webster_domain('geom')])).
ml_word('issue', noun, forms(['issue', 'issues']), demand([dataset(18)])).
ml_word('issue', verb, forms(['issue', 'issued', 'issues', 'issuing']), demand([dataset(18)])).
ml_word('italian', noun, forms(['italian', 'italians']), demand([dataset(4)])).
ml_word('italian', adjective, forms(['italian']), demand([dataset(4)])).
ml_word('italy', place_name, forms(['italy']), demand([dataset(2), supplement_class('place_name')])).
ml_word('item', noun, forms(['item', 'items']), demand([question_corpus(6), dataset(71)])).
ml_word('item', verb, forms(['item', 'itemed', 'iteming', 'items']), demand([question_corpus(6), dataset(71)])).
ml_word('item', adverb, forms(['item']), demand([question_corpus(3), dataset(34)])).
ml_word('itself', pronoun, forms(['itself']), demand([question_corpus(2)])).
ml_word('ittymangnark', given_name, forms(['ittymangnark']), demand([dataset(4), supplement_class('given_name')])).
ml_word('ivan', given_name, forms(['ivan']), demand([dataset(17), supplement_class('given_name')])).
ml_word('j', algebra_symbol, forms(['j']), demand([question_corpus(1), supplement_class('algebra_symbol')])).
ml_word('jace', given_name, forms(['jace']), demand([dataset(10), supplement_class('given_name')])).
ml_word('jack', noun, forms(['jack', 'jacks']), demand([dataset(70)])).
ml_word('jack', verb, forms(['jack', 'jacked', 'jacking', 'jacks']), demand([dataset(70)])).
ml_word('jackson', given_name, forms(['jackson']), demand([dataset(23), supplement_class('given_name')])).
ml_word('jaco', given_name, forms(['jaco']), demand([dataset(20), supplement_class('given_name')])).
ml_word('jacob', noun, forms(['jacob', 'jacobs']), demand([dataset(13)])).
ml_word('jada', given_name, forms(['jada']), demand([question_corpus(3), supplement_class('given_name')])).
ml_word('jake', given_name, forms(['jake']), demand([dataset(59), supplement_class('given_name')])).
ml_word('jalapeno', noun, forms(['jalapeno', 'jalapenos']), demand([dataset(13), supplement_class('common_noun')])).
ml_word('jam', noun, forms(['jam', 'jams']), demand([dataset(49)])).
ml_word('jam', verb, forms(['jam', 'jammed', 'jamming', 'jams']), demand([dataset(49)])).
ml_word('jame', given_name, forms(['jame']), demand([dataset(6), supplement_class('given_name')])).
ml_word('james', given_name, forms(['james']), demand([dataset(125), supplement_class('given_name')])).
ml_word('jan', noun, forms(['jan', 'jans']), demand([dataset(10)])).
ml_word('jane', noun, forms(['jane', 'janes']), demand([dataset(17)])).
ml_word('janet', given_name, forms(['janet']), demand([dataset(6), supplement_class('given_name')])).
ml_word('janice', given_name, forms(['janice']), demand([dataset(14), supplement_class('given_name')])).
ml_word('jar', noun, forms(['jar', 'jars']), demand([dataset(111)])).
ml_word('jar', verb, forms(['jar', 'jared', 'jaring', 'jarred', 'jarring', 'jars']), demand([dataset(111)])).
ml_word('jason', given_name, forms(['jason']), demand([dataset(21), supplement_class('given_name')])).
ml_word('javier', given_name, forms(['javier']), demand([dataset(6), supplement_class('given_name')])).
ml_word('jean', noun, forms(['jean', 'jeans']), demand([dataset(12)])).
ml_word('jeanette', given_name, forms(['jeanette']), demand([dataset(8), supplement_class('given_name')])).
ml_word('jeff', given_name, forms(['jeff']), demand([dataset(21), supplement_class('given_name')])).
ml_word('jeffrey', given_name, forms(['jeffrey']), demand([dataset(7), supplement_class('given_name')])).
ml_word('jelly', noun, forms(['jellies', 'jelly']), demand([dataset(42)])).
ml_word('jelly', verb, forms(['jellied', 'jellies', 'jelly', 'jellying']), demand([dataset(42)])).
ml_word('jen', given_name, forms(['jen']), demand([dataset(12), supplement_class('given_name')])).
ml_word('jenga', named_entity, forms(['jenga']), demand([dataset(2), supplement_class('named_entity')])).
ml_word('jennifer', given_name, forms(['jennifer']), demand([dataset(8), supplement_class('given_name')])).
ml_word('jenny', noun, forms(['jennies', 'jenny']), demand([dataset(44)])).
ml_word('jerry', given_name, forms(['jerry']), demand([dataset(31), supplement_class('given_name')])).
ml_word('jess', noun, forms(['jess', 'jesses']), demand([dataset(14)])).
ml_word('jesse', noun, forms(['jesse', 'jesses']), demand([dataset(5)])).
ml_word('jessica', given_name, forms(['jessica']), demand([dataset(18), supplement_class('given_name')])).
ml_word('jethro', given_name, forms(['jethro']), demand([dataset(20), supplement_class('given_name')])).
ml_word('jewelry', noun, forms(['jewelries', 'jewelry']), demand([dataset(4)])).
ml_word('jill', noun, forms(['jill', 'jills']), demand([dataset(31)])).
ml_word('jim', given_name, forms(['jim']), demand([dataset(44), supplement_class('given_name')])).
ml_word('jimmy', noun, forms(['jimmies', 'jimmy']), demand([dataset(9)])).
ml_word('jina', given_name, forms(['jina']), demand([dataset(11), supplement_class('given_name')])).
ml_word('joanie', given_name, forms(['joanie']), demand([dataset(12), supplement_class('given_name')])).
ml_word('job', noun, forms(['job', 'jobs']), demand([dataset(38)])).
ml_word('job', verb, forms(['job', 'jobbed', 'jobbing', 'jobed', 'jobing', 'jobs']), demand([dataset(38)])).
ml_word('joey', given_name, forms(['joey']), demand([dataset(55), supplement_class('given_name')])).
ml_word('jog', noun, forms(['jog', 'jogs']), demand([dataset(61)])).
ml_word('jog', verb, forms(['jog', 'joged', 'jogged', 'jogging', 'joging', 'jogs']), demand([dataset(61)])).
ml_word('john', noun, forms(['john', 'johns']), demand([dataset(219)])).
ml_word('johnny', noun, forms(['johnnies', 'johnny']), demand([dataset(31)])).
ml_word('johnson', family_name, forms(['johnson']), demand([dataset(16), supplement_class('family_name')])).
ml_word('join', noun, forms(['join', 'joins']), demand([dataset(13), webster_domain('geom')])).
ml_word('join', verb, forms(['join', 'joined', 'joining', 'joins']), demand([dataset(35), webster_domain('geom')])).
ml_word('jones', family_name, forms(['jones']), demand([dataset(8), supplement_class('family_name')])).
ml_word('jorge', given_name, forms(['jorge']), demand([dataset(3), supplement_class('given_name')])).
ml_word('jose', given_name, forms(['jose']), demand([dataset(7), supplement_class('given_name')])).
ml_word('josh', given_name, forms(['josh']), demand([dataset(63), supplement_class('given_name')])).
ml_word('journey', noun, forms(['journey', 'journeys']), demand([dataset(18)])).
ml_word('journey', verb, forms(['journey', 'journeyed', 'journeying', 'journeys']), demand([dataset(18)])).
ml_word('joy', noun, forms(['joy', 'joys']), demand([dataset(3)])).
ml_word('joy', verb, forms(['joy', 'joyed', 'joying', 'joys']), demand([dataset(3)])).
ml_word('jr', honorific, forms(['jr']), demand([dataset(1), supplement_class('honorific')])).
ml_word('juan', given_name, forms(['juan']), demand([dataset(20), supplement_class('given_name')])).
ml_word('judah', given_name, forms(['judah']), demand([dataset(5), supplement_class('given_name')])).
ml_word('jug', noun, forms(['jug', 'jugs']), demand([question_corpus(1)])).
ml_word('jug', verb, forms(['jug', 'juged', 'jugged', 'jugging', 'juging', 'jugs']), demand([question_corpus(1)])).
ml_word('juggle', noun, forms(['juggle', 'juggles']), demand([dataset(22)])).
ml_word('juggle', verb, forms(['juggle', 'juggled', 'juggles', 'juggling']), demand([dataset(66)])).
ml_word('juggling', noun, forms(['juggling', 'jugglings']), demand([dataset(44)])).
ml_word('juggling', adjective, forms(['juggling']), demand([dataset(44)])).
ml_word('juice', noun, forms(['juice', 'juices']), demand([question_corpus(1), dataset(12)])).
ml_word('juice', verb, forms(['juice', 'juiced', 'juices', 'juicing']), demand([question_corpus(1), dataset(12)])).
ml_word('julia', given_name, forms(['julia']), demand([dataset(114), supplement_class('given_name')])).
ml_word('julie', given_name, forms(['julie']), demand([dataset(18), supplement_class('given_name')])).
ml_word('july', noun, forms(['julies', 'july']), demand([dataset(5)])).
ml_word('jumbo', adjective, forms(['jumbo']), demand([dataset(7), supplement_class('adjective')])).
ml_word('jump', noun, forms(['jump', 'jumps']), demand([question_corpus(3), dataset(20)])).
ml_word('jump', verb, forms(['jump', 'jumped', 'jumping', 'jumps']), demand([question_corpus(3), dataset(20)])).
ml_word('jump', adjective, forms(['jump']), demand([question_corpus(3), dataset(10)])).
ml_word('jump', adverb, forms(['jump']), demand([question_corpus(3), dataset(10)])).
ml_word('junior', noun, forms(['junior', 'juniors']), demand([dataset(5)])).
ml_word('junior', adjective, forms(['junior']), demand([dataset(5)])).
ml_word('jupiter', noun, forms(['jupiter', 'jupiters']), demand([question_corpus(1)])).
ml_word('just', noun, forms(['just', 'justs']), demand([question_corpus(5), dataset(42)])).
ml_word('just', verb, forms(['just', 'justed', 'justing', 'justs']), demand([question_corpus(5), dataset(42)])).
ml_word('just', adjective, forms(['just']), demand([question_corpus(5), dataset(42)])).
ml_word('just', adverb, forms(['just']), demand([question_corpus(5), dataset(42)])).
ml_word('justify', verb, forms(['justified', 'justifies', 'justify', 'justifying']), demand([question_corpus(8)])).
ml_word('kamil', given_name, forms(['kamil']), demand([dataset(5), supplement_class('given_name')])).
ml_word('karan', given_name, forms(['karan']), demand([dataset(30), supplement_class('given_name')])).
ml_word('karina', given_name, forms(['karina']), demand([dataset(24), supplement_class('given_name')])).
ml_word('kart', noun, forms(['kart', 'karts']), demand([dataset(35), supplement_class('common_noun')])).
ml_word('katrina', given_name, forms(['katrina']), demand([dataset(9), supplement_class('given_name')])).
ml_word('kaylee', given_name, forms(['kaylee']), demand([dataset(4), supplement_class('given_name')])).
ml_word('keenan', given_name, forms(['keenan']), demand([dataset(5), supplement_class('given_name')])).
ml_word('keep', noun, forms(['keep', 'keeps']), demand([question_corpus(2), dataset(64)])).
ml_word('keep', verb, forms(['keep', 'keeping', 'keeps', 'kept']), demand([question_corpus(3), dataset(88)])).
ml_word('keeping', noun, forms(['keeping', 'keepings']), demand([dataset(3)])).
ml_word('ken', noun, forms(['ken', 'kens']), demand([dataset(25)])).
ml_word('ken', verb, forms(['ken', 'kened', 'kening', 'kens']), demand([dataset(25)])).
ml_word('kendra', given_name, forms(['kendra']), demand([dataset(32), supplement_class('given_name')])).
ml_word('kenny', given_name, forms(['kenny']), demand([dataset(20), supplement_class('given_name')])).
ml_word('kernel', noun, forms(['kernel', 'kernels']), demand([dataset(18)])).
ml_word('kernel', verb, forms(['kernel', 'kerneled', 'kerneling', 'kernels']), demand([dataset(18)])).
ml_word('kerry', given_name, forms(['kerry']), demand([dataset(15), supplement_class('given_name')])).
ml_word('kevin', noun, forms(['kevin', 'kevins']), demand([dataset(11)])).
ml_word('key', noun, forms(['key', 'keys']), demand([question_corpus(1)])).
ml_word('key', verb, forms(['keved', 'key', 'keying', 'keys']), demand([question_corpus(1)])).
ml_word('keziah', given_name, forms(['keziah']), demand([dataset(5), supplement_class('given_name')])).
ml_word('kg', unit_abbreviation, forms(['kg']), demand([dataset(143), supplement_class('unit_abbreviation')])).
ml_word('kgs', unit_abbreviation, forms(['kgs']), demand([dataset(12), supplement_class('unit_abbreviation')])).
ml_word('kick', verb, forms(['kick', 'kicked', 'kicking', 'kicks', 'kicred']), demand([dataset(51)])).
ml_word('kid', noun, forms(['kid', 'kids']), demand([question_corpus(4), dataset(74)])).
ml_word('kid', verb, forms(['kid', 'kidded', 'kidding', 'kided', 'kiding', 'kids']), demand([question_corpus(4), dataset(74)])).
ml_word('kiddie', adjective, forms(['kiddie']), demand([dataset(18), supplement_class('adjective')])).
ml_word('kiki', given_name, forms(['kiki']), demand([dataset(8), supplement_class('given_name')])).
ml_word('kilo', noun, forms(['kilo', 'kilos']), demand([dataset(14)])).
ml_word('kilobyte', noun, forms(['kilobyte', 'kilobytes']), demand([dataset(17), supplement_class('common_noun')])).
ml_word('kilogram', noun, forms(['kilogram', 'kilograms']), demand([dataset(6)])).
ml_word('kilometer', noun, forms(['kilometer', 'kilometers']), demand([question_corpus(1), dataset(10)])).
ml_word('kind', noun, forms(['kind', 'kinds']), demand([question_corpus(11), dataset(14)])).
ml_word('kind', verb, forms(['kind', 'kinded', 'kinding', 'kinds']), demand([question_corpus(11), dataset(14)])).
ml_word('kind', adjective, forms(['kind', 'kinder', 'kindest']), demand([question_corpus(3), dataset(10)])).
ml_word('king', noun, forms(['king', 'kings']), demand([dataset(8)])).
ml_word('king', verb, forms(['king', 'kinged', 'kinging', 'kings']), demand([dataset(8)])).
ml_word('kingnook', given_name, forms(['kingnook']), demand([dataset(2), supplement_class('given_name')])).
ml_word('kiran', given_name, forms(['kiran']), demand([question_corpus(4), supplement_class('given_name')])).
ml_word('kit', noun, forms(['kit', 'kits']), demand([dataset(7)])).
ml_word('kit', verb, forms(['kit', 'kited', 'kiting', 'kits']), demand([dataset(7)])).
ml_word('kitchen', noun, forms(['kitchen', 'kitchens']), demand([dataset(12)])).
ml_word('kitchen', verb, forms(['kitchen', 'kitchened', 'kitchening', 'kitchens']), demand([dataset(12)])).
ml_word('kiwi', noun, forms(['kiwi', 'kiwis']), demand([dataset(3), supplement_class('common_noun')])).
ml_word('km', unit_abbreviation, forms(['km']), demand([question_corpus(1), dataset(39), supplement_class('unit_abbreviation')])).
ml_word('knock', noun, forms(['knock', 'knocks']), demand([dataset(3)])).
ml_word('knock', verb, forms(['knock', 'knocked', 'knocking', 'knocks']), demand([dataset(5)])).
ml_word('knocking', noun, forms(['knocking', 'knockings']), demand([dataset(2)])).
ml_word('know', noun, forms(['know', 'knows']), demand([question_corpus(157), dataset(150)])).
ml_word('know', verb, forms(['knew', 'know', 'knowing', 'known', 'knows']), demand([question_corpus(169), dataset(160)])).
ml_word('knowing', noun, forms(['knowing', 'knowings']), demand([question_corpus(11), dataset(1)])).
ml_word('knowing', adjective, forms(['knowing']), demand([question_corpus(11), dataset(1)])).
ml_word('koala', noun, forms(['koala', 'koalas']), demand([dataset(10)])).
ml_word('kristin', given_name, forms(['kristin']), demand([dataset(12), supplement_class('given_name')])).
ml_word('kwh', unit_abbreviation, forms(['kwh']), demand([question_corpus(1), supplement_class('unit_abbreviation')])).
ml_word('kyle', given_name, forms(['kyle']), demand([dataset(12), supplement_class('given_name')])).
ml_word('l', unit_abbreviation, forms(['l']), demand([dataset(26), supplement_class('unit_abbreviation')])).
ml_word('la', noun, forms(['la', 'las']), demand([dataset(2)])).
ml_word('la', interjection, forms(['la']), demand([dataset(2)])).
ml_word('label', noun, forms(['label', 'labels']), demand([question_corpus(7)])).
ml_word('label', verb, forms(['label', 'labeled', 'labeling', 'labels']), demand([question_corpus(10)])).
ml_word('lady', noun, forms(['ladies', 'lady']), demand([dataset(2)])).
ml_word('lady', adjective, forms(['lady']), demand([dataset(2)])).
ml_word('lake', noun, forms(['lake', 'lakes']), demand([dataset(42)])).
ml_word('lake', verb, forms(['lake', 'laked', 'lakes', 'laking']), demand([dataset(42)])).
ml_word('land', noun, forms(['land', 'lands']), demand([question_corpus(1), dataset(25)])).
ml_word('land', verb, forms(['land', 'landed', 'landing', 'lands']), demand([question_corpus(1), dataset(27)])).
ml_word('landing', noun, forms(['landing', 'landings']), demand([dataset(2)])).
ml_word('landing', adjective, forms(['landing']), demand([dataset(2)])).
ml_word('landscaping', noun, forms(['landscaping']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('language', noun, forms(['language', 'languages']), demand([question_corpus(3)])).
ml_word('language', verb, forms(['language', 'languaged', 'languages', 'languaging']), demand([question_corpus(3)])).
ml_word('lap', noun, forms(['lap', 'laps']), demand([dataset(18)])).
ml_word('lap', verb, forms(['lap', 'laped', 'laping', 'lapped', 'lapping', 'laps']), demand([dataset(18)])).
ml_word('lara', given_name, forms(['lara']), demand([dataset(8), supplement_class('given_name')])).
ml_word('lard', noun, forms(['lard', 'lards']), demand([dataset(20)])).
ml_word('lard', verb, forms(['lard', 'larded', 'larding', 'lards']), demand([dataset(20)])).
ml_word('large', noun, forms(['large', 'larges']), demand([question_corpus(1), dataset(90)])).
ml_word('large', adjective, forms(['large', 'larger', 'largest']), demand([question_corpus(8), dataset(96)])).
ml_word('large', adverb, forms(['large']), demand([question_corpus(1), dataset(90)])).
ml_word('last', noun, forms(['last', 'lasts']), demand([question_corpus(46), dataset(138)])).
ml_word('last', verb, forms(['last', 'lasted', 'lasting', 'lasts']), demand([question_corpus(46), dataset(142)])).
ml_word('last', adverb, forms(['last']), demand([question_corpus(46), dataset(132)])).
ml_word('late', adjective, forms(['late', 'later', 'latest', 'latter']), demand([question_corpus(7), dataset(84)])).
ml_word('late', adverb, forms(['late']), demand([question_corpus(1), dataset(22)])).
ml_word('lately', adverb, forms(['lately']), demand([question_corpus(3)])).
ml_word('later', noun, forms(['later', 'lateres', 'laters']), demand([question_corpus(5), dataset(62)])).
ml_word('later', adjective, forms(['later']), demand([question_corpus(5), dataset(62)])).
ml_word('latte', noun, forms(['latte', 'lattes']), demand([dataset(7), supplement_class('common_noun')])).
ml_word('latter', adjective, forms(['latter']), demand([question_corpus(1)])).
ml_word('launch', verb, forms(['launch', 'launched', 'launches', 'launching']), demand([dataset(2)])).
ml_word('launderette', noun, forms(['launderette', 'launderettes']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('laundry', noun, forms(['laundries', 'laundry']), demand([dataset(35)])).
ml_word('laura', noun, forms(['laura', 'lauras']), demand([dataset(3)])).
ml_word('laurel', noun, forms(['laurel', 'laurels']), demand([dataset(24)])).
ml_word('lavender', noun, forms(['lavender', 'lavenders']), demand([dataset(20)])).
ml_word('lawn', noun, forms(['lawn', 'lawns']), demand([dataset(34)])).
ml_word('lawnmower', noun, forms(['lawnmower', 'lawnmowers']), demand([dataset(14), supplement_class('common_noun')])).
ml_word('lay', noun, forms(['lay', 'lays']), demand([question_corpus(2), dataset(7)])).
ml_word('lay', verb, forms(['laid', 'lay', 'laying', 'lays']), demand([question_corpus(2), dataset(23)])).
ml_word('lay', adjective, forms(['lay']), demand([question_corpus(2)])).
ml_word('layer', noun, forms(['layer', 'layers']), demand([dataset(8)])).
ml_word('lb', unit_abbreviation, forms(['lb']), demand([dataset(7), supplement_class('unit_abbreviation')])).
ml_word('lbs', unit_abbreviation, forms(['lbs']), demand([dataset(10), supplement_class('unit_abbreviation')])).
ml_word('lead', noun, forms(['lead', 'leads']), demand([question_corpus(5)])).
ml_word('lead', verb, forms(['lead', 'leading', 'leads', 'led']), demand([question_corpus(5)])).
ml_word('leader', noun, forms(['leader', 'leaders']), demand([dataset(4)])).
ml_word('leaf', noun, forms(['leaf', 'leaves']), demand([dataset(21)])).
ml_word('leaf', verb, forms(['leaf', 'leafed', 'leafing', 'leaves']), demand([dataset(21)])).
ml_word('league', noun, forms(['league', 'leagues']), demand([dataset(2)])).
ml_word('league', verb, forms(['league', 'leagued', 'leagues', 'leaguing']), demand([dataset(2)])).
ml_word('leah', given_name, forms(['leah']), demand([dataset(8), supplement_class('given_name')])).
ml_word('leak', noun, forms(['leak', 'leaks']), demand([dataset(7)])).
ml_word('leak', verb, forms(['leak', 'leaked', 'leaking', 'leaks']), demand([dataset(7)])).
ml_word('leak', adjective, forms(['leak']), demand([dataset(7)])).
ml_word('learn', verb, forms(['learn', 'learned', 'learning', 'learns']), demand([question_corpus(30), dataset(54)])).
ml_word('learned', adjective, forms(['learned']), demand([question_corpus(5)])).
ml_word('learner', noun, forms(['learner', 'learners']), demand([question_corpus(2)])).
ml_word('learning', noun, forms(['learning', 'learnings']), demand([question_corpus(21), dataset(30)])).
ml_word('least', adjective, forms(['least']), demand([dataset(32)])).
ml_word('least', adverb, forms(['least']), demand([dataset(32)])).
ml_word('least', conjunction, forms(['least']), demand([dataset(32)])).
ml_word('leave', noun, forms(['leave', 'leaves']), demand([dataset(40)])).
ml_word('leave', verb, forms(['leave', 'leaved', 'leaves', 'leaving', 'left']), demand([question_corpus(7), dataset(555)])).
ml_word('leaves', noun, forms(['leaves', 'leaveses']), demand([dataset(21)])).
ml_word('lee', noun, forms(['lee', 'lees']), demand([dataset(6)])).
ml_word('lee', adjective, forms(['lee']), demand([dataset(6)])).
ml_word('left', noun, forms(['left', 'lefts']), demand([question_corpus(6), dataset(500)])).
ml_word('left', adjective, forms(['left']), demand([question_corpus(6), dataset(500)])).
ml_word('leftover', noun, forms(['leftover', 'leftovers']), demand([question_corpus(1), dataset(23), supplement_class('common_noun')])).
ml_word('leg', noun, forms(['leg', 'legs']), demand([dataset(49)])).
ml_word('leg', verb, forms(['leg', 'leged', 'leging', 'legs']), demand([dataset(49)])).
ml_word('lego', named_entity, forms(['lego']), demand([dataset(45), supplement_class('named_entity')])).
ml_word('leila', given_name, forms(['leila']), demand([dataset(10), supplement_class('given_name')])).
ml_word('lemon', noun, forms(['lemon', 'lemons']), demand([dataset(10)])).
ml_word('lemonade', noun, forms(['lemonade', 'lemonades']), demand([question_corpus(1), dataset(37)])).
ml_word('lena', noun, forms(['lena', 'lenas']), demand([dataset(8)])).
ml_word('lend', verb, forms(['lend', 'lending', 'lends', 'lent']), demand([dataset(2)])).
ml_word('lending', noun, forms(['lending', 'lendings']), demand([dataset(2)])).
ml_word('length', noun, forms(['length', 'lengths']), demand([question_corpus(27), dataset(93)])).
ml_word('length', verb, forms(['length', 'lengthed', 'lengthing', 'lengths']), demand([question_corpus(27), dataset(93)])).
ml_word('leo', noun, forms(['leo', 'leos']), demand([dataset(14)])).
ml_word('less', noun, forms(['less', 'lesses']), demand([question_corpus(22), dataset(131)])).
ml_word('less', verb, forms(['less', 'lessed', 'lesses', 'lessing']), demand([question_corpus(22), dataset(131)])).
ml_word('less', adjective, forms(['least', 'less', 'lesser']), demand([question_corpus(22), dataset(163)])).
ml_word('less', adverb, forms(['less']), demand([question_corpus(22), dataset(131)])).
ml_word('lesson', noun, forms(['lesson', 'lessons']), demand([question_corpus(6)])).
ml_word('lesson', verb, forms(['lesson', 'lessoned', 'lessoning', 'lessons']), demand([question_corpus(6)])).
ml_word('let', noun, forms(['let', 'lets']), demand([dataset(266)])).
ml_word('let', verb, forms(['let', 'leted', 'leting', 'lets', 'letting']), demand([dataset(270)])).
ml_word('lette', verb, forms(['lette', 'letted', 'lettes', 'letting']), demand([dataset(4)])).
ml_word('letter', noun, forms(['letter', 'letters']), demand([question_corpus(2)])).
ml_word('letter', verb, forms(['letter', 'lettered', 'lettering', 'letters']), demand([question_corpus(2)])).
ml_word('level', noun, forms(['level', 'levels']), demand([question_corpus(2), dataset(35)])).
ml_word('level', verb, forms(['level', 'leveled', 'leveling', 'levels']), demand([question_corpus(2), dataset(35)])).
ml_word('level', adjective, forms(['level']), demand([question_corpus(2), dataset(33)])).
ml_word('leverage', noun, forms(['leverage', 'leverages']), demand([question_corpus(3)])).
ml_word('leverage', verb, forms(['leverage', 'leveraged', 'leverages', 'leveraging']), demand([question_corpus(3), supplement_class('corpus_verb')])).
ml_word('levi', given_name, forms(['levi']), demand([dataset(45), supplement_class('given_name')])).
ml_word('liam', given_name, forms(['liam']), demand([dataset(3), supplement_class('given_name')])).
ml_word('library', noun, forms(['libraries', 'library']), demand([question_corpus(1), dataset(35)])).
ml_word('lid', noun, forms(['lid', 'lids']), demand([dataset(4)])).
ml_word('life', noun, forms(['life', 'lives']), demand([question_corpus(2), dataset(18)])).
ml_word('lift', noun, forms(['lift', 'lifts']), demand([dataset(65)])).
ml_word('lift', verb, forms(['lift', 'lifted', 'lifting', 'lifts']), demand([dataset(73)])).
ml_word('lifting', adjective, forms(['lifting']), demand([dataset(6)])).
ml_word('light', noun, forms(['light', 'lights']), demand([dataset(23)])).
ml_word('light', verb, forms(['light', 'lighted', 'lighting', 'lights']), demand([dataset(23)])).
ml_word('light', adjective, forms(['light', 'lighted', 'lighter', 'lightest']), demand([dataset(10)])).
ml_word('light', adverb, forms(['light']), demand([dataset(4)])).
ml_word('like', noun, forms(['like', 'likes']), demand([question_corpus(34), dataset(118)])).
ml_word('like', verb, forms(['like', 'liked', 'likes', 'liking']), demand([question_corpus(34), dataset(122)])).
ml_word('like', adjective, forms(['like', 'liker', 'likest']), demand([question_corpus(33), dataset(84)])).
ml_word('like', adverb, forms(['like']), demand([question_corpus(33), dataset(84)])).
ml_word('likelihood', noun, forms(['likelihood', 'likelihoods']), demand([question_corpus(1)])).
ml_word('likely', adjective, forms(['likelier', 'likeliest', 'likely']), demand([question_corpus(3)])).
ml_word('likely', adverb, forms(['likely']), demand([question_corpus(3)])).
ml_word('lilac', noun, forms(['lilac', 'lilacs']), demand([dataset(4)])).
ml_word('lilibeth', given_name, forms(['lilibeth']), demand([dataset(24), supplement_class('given_name')])).
ml_word('lilith', given_name, forms(['lilith']), demand([dataset(11), supplement_class('given_name')])).
ml_word('lillian', given_name, forms(['lillian']), demand([dataset(8), supplement_class('given_name')])).
ml_word('lily', noun, forms(['lilies', 'lily']), demand([dataset(20)])).
ml_word('limit', noun, forms(['limit', 'limits']), demand([dataset(4)])).
ml_word('limit', verb, forms(['limit', 'limited', 'limiting', 'limits']), demand([dataset(4)])).
ml_word('limitation', noun, forms(['limitation', 'limitations']), demand([question_corpus(1)])).
ml_word('lin', noun, forms(['lin', 'lins']), demand([question_corpus(7)])).
ml_word('lin', verb, forms(['lin', 'lined', 'lining', 'lins']), demand([question_corpus(7)])).
ml_word('line', noun, forms(['line', 'lines']), demand([question_corpus(45), dataset(19), questioning_paper_lexicon])).
ml_word('line', verb, forms(['line', 'lined', 'lines', 'lining']), demand([question_corpus(45), dataset(19), questioning_paper_lexicon])).
ml_word('linear', adjective, forms(['linear']), demand([question_corpus(1), dataset(1)])).
ml_word('link', verb, forms(['link', 'linked', 'linking', 'links']), demand([dataset(2)])).
ml_word('lion', noun, forms(['lion', 'lions']), demand([dataset(8)])).
ml_word('liquid', noun, forms(['liquid', 'liquids']), demand([question_corpus(1), dataset(17)])).
ml_word('liquid', adjective, forms(['liquid']), demand([question_corpus(1), dataset(17)])).
ml_word('lisa', given_name, forms(['lisa']), demand([dataset(56), supplement_class('given_name')])).
ml_word('list', noun, forms(['list', 'lists']), demand([question_corpus(58)])).
ml_word('list', verb, forms(['list', 'listed', 'listing', 'lists']), demand([question_corpus(59), dataset(6)])).
ml_word('listen', verb, forms(['listen', 'listened', 'listening', 'listens']), demand([dataset(2)])).
ml_word('liter', noun, forms(['liter', 'liters']), demand([dataset(90)])).
ml_word('litter', noun, forms(['litter', 'litters']), demand([dataset(38)])).
ml_word('litter', verb, forms(['litter', 'littered', 'littering', 'litters']), demand([dataset(38)])).
ml_word('litter', adjective, forms(['litter']), demand([dataset(38)])).
ml_word('little', noun, forms(['little', 'littles']), demand([question_corpus(3), dataset(10)])).
ml_word('little', adjective, forms(['little']), demand([question_corpus(3), dataset(10)])).
ml_word('little', adverb, forms(['little']), demand([question_corpus(3), dataset(10)])).
ml_word('live', noun, forms(['live', 'lives']), demand([question_corpus(1), dataset(8)])).
ml_word('live', verb, forms(['live', 'lived', 'lives', 'living']), demand([question_corpus(1), dataset(41)])).
ml_word('live', adjective, forms(['live']), demand([question_corpus(1), dataset(5)])).
ml_word('lives', noun, forms(['lives', 'liveses']), demand([dataset(3)])).
ml_word('lives', adjective, forms(['lives']), demand([dataset(3)])).
ml_word('lives', adverb, forms(['lives']), demand([dataset(3)])).
ml_word('living', noun, forms(['living', 'livings']), demand([dataset(33)])).
ml_word('living', adjective, forms(['living']), demand([dataset(33)])).
ml_word('lizard', noun, forms(['lizard', 'lizards']), demand([question_corpus(1)])).
ml_word('load', noun, forms(['load', 'loads']), demand([dataset(38)])).
ml_word('load', verb, forms(['load', 'loaded', 'loading', 'loads']), demand([dataset(40)])).
ml_word('loading', noun, forms(['loading', 'loadings']), demand([dataset(2)])).
ml_word('loaf', noun, forms(['loaf', 'loaves']), demand([dataset(12)])).
ml_word('loaf', verb, forms(['loaf', 'loafed', 'loafing', 'loaves']), demand([dataset(12)])).
ml_word('loan', noun, forms(['loan', 'loans']), demand([dataset(20)])).
ml_word('loan', verb, forms(['loan', 'loaned', 'loaning', 'loans']), demand([dataset(20)])).
ml_word('loaves', noun, forms(['loaves', 'loaveses']), demand([dataset(6)])).
ml_word('local', noun, forms(['local', 'locals']), demand([dataset(14)])).
ml_word('local', adjective, forms(['local']), demand([dataset(14)])).
ml_word('locate', verb, forms(['locate', 'located', 'locates', 'locating']), demand([question_corpus(2), dataset(6)])).
ml_word('location', noun, forms(['location', 'locations']), demand([question_corpus(5), dataset(6)])).
ml_word('lock', verb, forms(['lock', 'locked', 'locking', 'locks']), demand([dataset(2)])).
ml_word('locker', noun, forms(['locker', 'lockers']), demand([question_corpus(1)])).
ml_word('log', noun, forms(['log', 'logs']), demand([dataset(20)])).
ml_word('log', verb, forms(['log', 'loged', 'logged', 'logging', 'loging', 'logs']), demand([dataset(20)])).
ml_word('logic', noun, forms(['logic', 'logics']), demand([dataset(2)])).
ml_word('lollipop', noun, forms(['lollipop', 'lollipops']), demand([dataset(17)])).
ml_word('long', noun, forms(['long', 'longs']), demand([question_corpus(11), dataset(198)])).
ml_word('long', verb, forms(['long', 'longed', 'longing', 'longs']), demand([question_corpus(11), dataset(198)])).
ml_word('long', adjective, forms(['long', 'longer', 'longest']), demand([question_corpus(20), dataset(235)])).
ml_word('long', adverb, forms(['long']), demand([question_corpus(11), dataset(198)])).
ml_word('long', preposition, forms(['long']), demand([question_corpus(11), dataset(198)])).
ml_word('longer', noun, forms(['longer', 'longers']), demand([question_corpus(6), dataset(37)])).
ml_word('look', noun, forms(['look', 'looks']), demand([question_corpus(24), dataset(6)])).
ml_word('look', verb, forms(['look', 'looked', 'looking', 'looks']), demand([question_corpus(30), dataset(18)])).
ml_word('looking', noun, forms(['looking', 'lookings']), demand([question_corpus(6)])).
ml_word('looking', adjective, forms(['looking']), demand([question_corpus(6)])).
ml_word('loose', noun, forms(['loose', 'looses']), demand([dataset(20)])).
ml_word('loose', verb, forms(['loose', 'loosed', 'looses', 'loosing']), demand([dataset(20)])).
ml_word('loose', adjective, forms(['loose', 'looser', 'loosest']), demand([dataset(20)])).
ml_word('loot', noun, forms(['loot', 'loots']), demand([dataset(10)])).
ml_word('loot', verb, forms(['loot', 'looted', 'looting', 'loots']), demand([dataset(10)])).
ml_word('lopez', family_name, forms(['lopez']), demand([dataset(8), supplement_class('family_name')])).
ml_word('lori', noun, forms(['lori', 'loris']), demand([dataset(16)])).
ml_word('los', noun, forms(['los', 'loses']), demand([dataset(53)])).
ml_word('lose', verb, forms(['lose', 'losed', 'loses', 'losing']), demand([dataset(104)])).
ml_word('losing', adjective, forms(['losing']), demand([dataset(13)])).
ml_word('loss', noun, forms(['loss', 'losses']), demand([dataset(10)])).
ml_word('lost', adjective, forms(['lost']), demand([dataset(49)])).
ml_word('lot', noun, forms(['lot', 'lots']), demand([question_corpus(1), dataset(32)])).
ml_word('lot', verb, forms(['lot', 'lots', 'lotted', 'lotting']), demand([question_corpus(1), dataset(32)])).
ml_word('lou', given_name, forms(['lou']), demand([dataset(6), supplement_class('given_name')])).
ml_word('louie', given_name, forms(['louie']), demand([dataset(10), supplement_class('given_name')])).
ml_word('love', noun, forms(['love', 'loves']), demand([question_corpus(1), dataset(6)])).
ml_word('love', verb, forms(['love', 'loved', 'loves', 'loving']), demand([question_corpus(1), dataset(6)])).
ml_word('low', noun, forms(['low', 'lows']), demand([question_corpus(5), dataset(10)])).
ml_word('low', verb, forms(['low', 'lowed', 'lowing', 'lows']), demand([question_corpus(5), dataset(10)])).
ml_word('low', adjective, forms(['low', 'lower', 'lowest']), demand([question_corpus(5), dataset(30)])).
ml_word('low', adverb, forms(['low']), demand([question_corpus(5), dataset(10)])).
ml_word('lower', noun, forms(['lower', 'lowers']), demand([dataset(6)])).
ml_word('lower', verb, forms(['lower', 'lowered', 'lowering', 'lowers']), demand([dataset(6)])).
ml_word('lower', adjective, forms(['lower']), demand([dataset(6)])).
ml_word('loyalty', noun, forms(['loyalties', 'loyalty']), demand([dataset(6)])).
ml_word('lucian', given_name, forms(['lucian']), demand([dataset(4), supplement_class('given_name')])).
ml_word('luck', noun, forms(['luck', 'lucks']), demand([question_corpus(1)])).
ml_word('luke', adjective, forms(['luke']), demand([dataset(4)])).
ml_word('lunar', noun, forms(['lunar', 'lunars']), demand([question_corpus(1)])).
ml_word('lunar', adjective, forms(['lunar']), demand([question_corpus(1)])).
ml_word('lunch', noun, forms(['lunch', 'lunches']), demand([dataset(88)])).
ml_word('lunch', verb, forms(['lunch', 'lunched', 'lunches', 'lunching']), demand([dataset(88)])).
ml_word('luncheon', noun, forms(['luncheon', 'luncheons']), demand([dataset(2)])).
ml_word('luncheon', verb, forms(['luncheon', 'luncheoned', 'luncheoning', 'luncheons']), demand([dataset(2)])).
ml_word('lupus', noun, forms(['lupus', 'lupuses']), demand([dataset(2)])).
ml_word('lyle', given_name, forms(['lyle']), demand([dataset(9), supplement_class('given_name')])).
ml_word('m', algebra_symbol, forms(['m']), demand([dataset(91), supplement_class('algebra_symbol')])).
ml_word('mabel', given_name, forms(['mabel']), demand([dataset(9), supplement_class('given_name')])).
ml_word('mac', given_name, forms(['mac']), demand([dataset(9), supplement_class('given_name')])).
ml_word('machine', noun, forms(['machine', 'machines']), demand([dataset(40)])).
ml_word('machine', verb, forms(['machine', 'machined', 'machines', 'machining']), demand([dataset(40)])).
ml_word('mack', given_name, forms(['mack']), demand([dataset(2), supplement_class('given_name')])).
ml_word('mad', noun, forms(['mad', 'mads']), demand([question_corpus(2), dataset(2)])).
ml_word('mad', verb, forms(['mad', 'madded', 'madding', 'maded', 'mading', 'mads']), demand([question_corpus(2), dataset(2)])).
ml_word('mad', adjective, forms(['mad', 'madder', 'maddest']), demand([question_corpus(1), dataset(2)])).
ml_word('made', noun, forms(['made', 'mades']), demand([question_corpus(10), dataset(183)])).
ml_word('made', adjective, forms(['made']), demand([question_corpus(10), dataset(183)])).
ml_word('madeline', given_name, forms(['madeline']), demand([dataset(35), supplement_class('given_name')])).
ml_word('magazine', noun, forms(['magazine', 'magazines']), demand([dataset(4)])).
ml_word('magazine', verb, forms(['magazine', 'magazined', 'magazines', 'magazining']), demand([dataset(4)])).
ml_word('magnet', noun, forms(['magnet', 'magnets']), demand([dataset(42)])).
ml_word('mai', given_name, forms(['mai']), demand([question_corpus(3), supplement_class('given_name')])).
ml_word('mailbox', noun, forms(['mailbox', 'mailboxes']), demand([dataset(5), supplement_class('common_noun')])).
ml_word('maintain', verb, forms(['maintain', 'maintained', 'maintaining', 'maintains']), demand([dataset(1)])).
ml_word('maintenance', noun, forms(['maintenance', 'maintenances']), demand([dataset(4)])).
ml_word('make', noun, forms(['make', 'makes']), demand([question_corpus(90), dataset(563)])).
ml_word('make', verb, forms(['made', 'make', 'makes', 'making']), demand([question_corpus(110), dataset(828)])).
ml_word('making', noun, forms(['making', 'makings']), demand([question_corpus(10), dataset(82)])).
ml_word('malaria', noun, forms(['malaria', 'malarias']), demand([dataset(8)])).
ml_word('male', noun, forms(['male', 'males']), demand([dataset(50)])).
ml_word('male', adjective, forms(['male']), demand([dataset(15)])).
ml_word('mall', noun, forms(['mall', 'malls']), demand([dataset(12)])).
ml_word('mall', verb, forms(['mall', 'malled', 'malling', 'malls']), demand([dataset(12)])).
ml_word('man', noun, forms(['man', 'men']), demand([dataset(44)])).
ml_word('man', verb, forms(['man', 'manned', 'manning', 'mans']), demand([dataset(5)])).
ml_word('manage', noun, forms(['manage', 'manages']), demand([dataset(2)])).
ml_word('manage', verb, forms(['manage', 'managed', 'manages', 'managing']), demand([dataset(4)])).
ml_word('mandy', given_name, forms(['mandy']), demand([dataset(8), supplement_class('given_name')])).
ml_word('mango', noun, forms(['mango', 'mangoes', 'mangos']), demand([dataset(57)])).
ml_word('manner', noun, forms(['manner', 'manners']), demand([dataset(1)])).
ml_word('manny', given_name, forms(['manny']), demand([dataset(9), supplement_class('given_name')])).
ml_word('manteau', noun, forms(['f', 'manteau', 'manteaus', 'manteaux']), demand([dataset(12)])).
ml_word('manual', noun, forms(['manual', 'manuals']), demand([dataset(8)])).
ml_word('manual', adjective, forms(['manual']), demand([dataset(8)])).
ml_word('manufacture', noun, forms(['manufacture', 'manufactures']), demand([dataset(12)])).
ml_word('manufacture', verb, forms(['manufacture', 'manufactured', 'manufactures', 'manufacturing']), demand([dataset(12)])).
ml_word('many', noun, forms(['manies', 'many']), demand([question_corpus(193), dataset(1560)])).
ml_word('many', adjective, forms(['many']), demand([question_corpus(193), dataset(1560)])).
ml_word('map', noun, forms(['map', 'maps']), demand([question_corpus(6)])).
ml_word('map', verb, forms(['map', 'mapped', 'mapping', 'maps']), demand([question_corpus(6)])).
ml_word('mar', noun, forms(['mar', 'mars']), demand([dataset(16)])).
ml_word('mar', verb, forms(['mar', 'marred', 'marring', 'mars']), demand([dataset(16)])).
ml_word('marathon', noun, forms(['marathon', 'marathons']), demand([dataset(5), supplement_class('common_noun')])).
ml_word('marble', noun, forms(['marble', 'marbles']), demand([dataset(180)])).
ml_word('marble', verb, forms(['marble', 'marbled', 'marbles', 'marbling']), demand([dataset(180)])).
ml_word('marble', adjective, forms(['marble']), demand([dataset(5)])).
ml_word('march', noun, forms(['march', 'marches']), demand([dataset(12)])).
ml_word('march', verb, forms(['march', 'marched', 'marches', 'marching']), demand([dataset(12)])).
ml_word('marco', given_name, forms(['marco']), demand([dataset(4), supplement_class('given_name')])).
ml_word('marcus', given_name, forms(['marcus']), demand([dataset(14), supplement_class('given_name')])).
ml_word('marcy', given_name, forms(['marcy']), demand([dataset(39), supplement_class('given_name')])).
ml_word('margaret', given_name, forms(['margaret']), demand([dataset(3), supplement_class('given_name')])).
ml_word('marian', adjective, forms(['marian']), demand([dataset(6)])).
ml_word('marinara', noun, forms(['marinara', 'marinaras']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('marissa', given_name, forms(['marissa']), demand([dataset(8), supplement_class('given_name')])).
ml_word('mark', noun, forms(['mark', 'marks']), demand([question_corpus(9), dataset(18)])).
ml_word('mark', verb, forms(['mark', 'marked', 'marking', 'marks']), demand([question_corpus(10), dataset(20)])).
ml_word('marked', adjective, forms(['marked']), demand([question_corpus(1), dataset(2)])).
ml_word('market', noun, forms(['market', 'markets']), demand([dataset(21)])).
ml_word('market', verb, forms(['market', 'marketed', 'marketing', 'markets']), demand([dataset(21)])).
ml_word('marking', noun, forms(['marking', 'markings']), demand([question_corpus(1)])).
ml_word('marla', given_name, forms(['marla']), demand([dataset(8), supplement_class('given_name')])).
ml_word('marriage', noun, forms(['marriage', 'marriages']), demand([dataset(10)])).
ml_word('married', adjective, forms(['married']), demand([dataset(8)])).
ml_word('marry', verb, forms(['married', 'marries', 'marry', 'marrying']), demand([dataset(8)])).
ml_word('mars', noun, forms(['mars', 'marses']), demand([dataset(16)])).
ml_word('marshmallow', noun, forms(['marshmallow', 'marshmallows']), demand([dataset(19), supplement_class('common_noun')])).
ml_word('martha', given_name, forms(['martha']), demand([dataset(19), supplement_class('given_name')])).
ml_word('martin', noun, forms(['martin', 'martins']), demand([dataset(27)])).
ml_word('marvin', given_name, forms(['marvin']), demand([dataset(10), supplement_class('given_name')])).
ml_word('mascot', noun, forms(['mascot', 'mascots']), demand([dataset(7)])).
ml_word('mask', noun, forms(['mask', 'masks']), demand([dataset(9)])).
ml_word('mask', verb, forms(['mask', 'masked', 'masking', 'masks']), demand([dataset(9)])).
ml_word('mason', noun, forms(['mason', 'masons']), demand([dataset(11)])).
ml_word('mason', verb, forms(['mason', 'masoned', 'masoning', 'masons']), demand([dataset(11)])).
ml_word('master', noun, forms(['master', 'masters']), demand([dataset(7)])).
ml_word('master', verb, forms(['master', 'mastered', 'mastering', 'masters']), demand([dataset(7)])).
ml_word('match', noun, forms(['match', 'matches']), demand([question_corpus(25), dataset(11)])).
ml_word('match', verb, forms(['match', 'matched', 'matches', 'matching']), demand([question_corpus(27), dataset(15)])).
ml_word('material', noun, forms(['material', 'materials']), demand([question_corpus(1), dataset(6)])).
ml_word('material', verb, forms(['material', 'materialed', 'materialing', 'materials']), demand([question_corpus(1), dataset(6)])).
ml_word('material', adjective, forms(['material']), demand([dataset(6)])).
ml_word('math', noun, forms(['math', 'maths']), demand([question_corpus(16), dataset(62)])).
ml_word('mathematical', adjective, forms(['mathematical']), demand([question_corpus(7)])).
ml_word('mathematician', noun, forms(['mathematician', 'mathematicians']), demand([question_corpus(3)])).
ml_word('mathematics', noun, forms(['mathematics', 'mathematicses']), demand([question_corpus(1)])).
ml_word('matilda', given_name, forms(['matilda']), demand([dataset(14), supplement_class('given_name')])).
ml_word('matt', noun, forms(['matt', 'matts']), demand([dataset(35)])).
ml_word('matter', noun, forms(['matter', 'matters']), demand([question_corpus(2)])).
ml_word('matter', verb, forms(['matter', 'mattered', 'mattering', 'matters']), demand([question_corpus(2)])).
ml_word('matthew', given_name, forms(['matthew']), demand([dataset(8), supplement_class('given_name')])).
ml_word('mattress', noun, forms(['mattress', 'mattresses']), demand([dataset(8)])).
ml_word('maturity', noun, forms(['maturities', 'maturity']), demand([dataset(3)])).
ml_word('max', given_name, forms(['max']), demand([dataset(49), supplement_class('given_name')])).
ml_word('maximum', noun, forms(['maxima', 'maximum', 'maximums']), demand([dataset(18)])).
ml_word('maximum', adjective, forms(['maximum']), demand([dataset(18)])).
ml_word('maya', noun, forms(['maya', 'mayas']), demand([dataset(28)])).
ml_word('maze', noun, forms(['maze', 'mazes']), demand([dataset(52)])).
ml_word('maze', verb, forms(['maze', 'mazed', 'mazes', 'mazing']), demand([dataset(52)])).
ml_word('meal', noun, forms(['meal', 'meals']), demand([dataset(104)])).
ml_word('meal', verb, forms(['meal', 'mealed', 'mealing', 'meals']), demand([dataset(104)])).
ml_word('mealworm', noun, forms(['mealworm', 'mealworms']), demand([dataset(16), supplement_class('common_noun')])).
ml_word('mean', noun, forms(['mean', 'means']), demand([question_corpus(33), dataset(195), questioning_paper_lexicon])).
ml_word('mean', verb, forms(['mean', 'meaned', 'meaning', 'means', 'meant']), demand([question_corpus(35), dataset(224), questioning_paper_lexicon])).
ml_word('mean', adjective, forms(['mean', 'meaner', 'meanest']), demand([question_corpus(29), dataset(4), questioning_paper_lexicon])).
ml_word('meaning', noun, forms(['meaning', 'meanings']), demand([question_corpus(2), dataset(27)])).
ml_word('meanwhile', noun, forms(['meanwhile', 'meanwhiles']), demand([dataset(4)])).
ml_word('meanwhile', adverb, forms(['meanwhile']), demand([dataset(4)])).
ml_word('measure', noun, forms(['measure', 'measures']), demand([question_corpus(22), dataset(5)])).
ml_word('measure', verb, forms(['measure', 'measured', 'measures', 'measuring']), demand([question_corpus(31), dataset(7)])).
ml_word('measured', adjective, forms(['measured']), demand([question_corpus(6)])).
ml_word('measurement', noun, forms(['measurement', 'measurements']), demand([question_corpus(10), dataset(2)])).
ml_word('measuring', adjective, forms(['measuring']), demand([question_corpus(3), dataset(2)])).
ml_word('meat', noun, forms(['meat', 'meats']), demand([dataset(74)])).
ml_word('meat', verb, forms(['meat', 'meated', 'meating', 'meats']), demand([dataset(74)])).
ml_word('mechanic', noun, forms(['mechanic', 'mechanics']), demand([dataset(57)])).
ml_word('mechanic', adjective, forms(['mechanic']), demand([dataset(57)])).
ml_word('median', noun, forms(['median', 'medians']), demand([question_corpus(1), questioning_paper_lexicon, webster_domain('geom')])).
ml_word('median', adjective, forms(['median']), demand([question_corpus(1), questioning_paper_lexicon, webster_domain('geom')])).
ml_word('medical', adjective, forms(['medical']), demand([dataset(11)])).
ml_word('medicine', noun, forms(['medicine', 'medicines']), demand([question_corpus(1), dataset(15)])).
ml_word('medicine', verb, forms(['medicine', 'medicined', 'medicines', 'medicining']), demand([question_corpus(1), dataset(15)])).
ml_word('medium', noun, forms(['media', 'medium', 'mediums']), demand([dataset(11)])).
ml_word('medium', adjective, forms(['medium']), demand([dataset(11)])).
ml_word('meet', noun, forms(['meet', 'meets']), demand([dataset(28)])).
ml_word('meet', verb, forms(['meet', 'meeting', 'meets', 'met']), demand([dataset(30)])).
ml_word('meet', adjective, forms(['meet']), demand([dataset(24)])).
ml_word('meet', adverb, forms(['meet']), demand([dataset(24)])).
ml_word('meg', given_name, forms(['meg']), demand([dataset(42), supplement_class('given_name')])).
ml_word('megan', given_name, forms(['megan']), demand([dataset(2), supplement_class('given_name')])).
ml_word('meghan', given_name, forms(['meghan']), demand([dataset(2), supplement_class('given_name')])).
ml_word('melanie', given_name, forms(['melanie']), demand([dataset(56), supplement_class('given_name')])).
ml_word('melon', noun, forms(['melon', 'melons']), demand([question_corpus(1), dataset(22)])).
ml_word('member', noun, forms(['member', 'members']), demand([question_corpus(1), dataset(66)])).
ml_word('member', verb, forms(['member', 'membered', 'membering', 'members']), demand([question_corpus(1), dataset(66)])).
ml_word('memory', noun, forms(['memories', 'memory']), demand([dataset(2)])).
ml_word('men', noun, forms(['men', 'mens']), demand([dataset(39)])).
ml_word('men', pronoun, forms(['men']), demand([dataset(39)])).
ml_word('mentally', adverb, forms(['mentally']), demand([question_corpus(5)])).
ml_word('mention', verb, forms(['mention', 'mentioned', 'mentioning', 'mentions']), demand([question_corpus(1)])).
ml_word('merchandise', noun, forms(['merchandise', 'merchandises']), demand([dataset(1)])).
ml_word('merchandise', verb, forms(['merchandise', 'merchandised', 'merchandises', 'merchandising']), demand([dataset(1)])).
ml_word('metal', verb, forms(['metal', 'metaled', 'metaling', 'metals']), demand([dataset(3)])).
ml_word('meter', noun, forms(['meter', 'meters']), demand([question_corpus(2), dataset(56)])).
ml_word('method', noun, forms(['method', 'methods']), demand([question_corpus(29)])).
ml_word('michael', given_name, forms(['michael']), demand([dataset(8), supplement_class('given_name')])).
ml_word('michel', given_name, forms(['michel']), demand([dataset(10), supplement_class('given_name')])).
ml_word('middle', noun, forms(['middle', 'middles']), demand([dataset(2)])).
ml_word('middle', adjective, forms(['middle']), demand([dataset(2)])).
ml_word('midnight', noun, forms(['midnight', 'midnights']), demand([dataset(5)])).
ml_word('midnight', adjective, forms(['midnight']), demand([dataset(5)])).
ml_word('midterm', noun, forms(['midterm', 'midterms']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('mikaela', given_name, forms(['mikaela']), demand([dataset(5), supplement_class('given_name')])).
ml_word('mike', given_name, forms(['mike']), demand([dataset(3), supplement_class('given_name')])).
ml_word('mila', given_name, forms(['mila']), demand([dataset(9), supplement_class('given_name')])).
ml_word('mile', noun, forms(['mile', 'miles']), demand([question_corpus(2), dataset(411)])).
ml_word('mileage', noun, forms(['mileage']), demand([question_corpus(1), dataset(6), supplement_class('common_noun')])).
ml_word('military', noun, forms(['militaries', 'military']), demand([dataset(2)])).
ml_word('military', adjective, forms(['military']), demand([dataset(2)])).
ml_word('milk', noun, forms(['milk', 'milks']), demand([question_corpus(1), dataset(80)])).
ml_word('milk', verb, forms(['milk', 'milked', 'milking', 'milks']), demand([question_corpus(1), dataset(80)])).
ml_word('milkshake', noun, forms(['milkshake', 'milkshakes']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('milliliter', noun, forms(['milliliter', 'milliliters']), demand([question_corpus(2), dataset(17)])).
ml_word('million', noun, forms(['million', 'millions']), demand([dataset(54)])).
ml_word('milly', given_name, forms(['milly']), demand([dataset(7), supplement_class('given_name')])).
ml_word('min', unit_abbreviation, forms(['min']), demand([dataset(4), supplement_class('unit_abbreviation')])).
ml_word('mini', adjective, forms(['mini']), demand([dataset(81), supplement_class('adjective')])).
ml_word('minibus', noun, forms(['minibus', 'minibuses']), demand([dataset(2)])).
ml_word('minimum', noun, forms(['minima', 'minimum', 'minimums']), demand([dataset(28)])).
ml_word('minus', adjective, forms(['minus']), demand([dataset(15)])).
ml_word('miss', noun, forms(['miss', 'misses']), demand([question_corpus(1), dataset(17)])).
ml_word('miss', verb, forms(['miss', 'missed', 'misses', 'missing']), demand([question_corpus(5), dataset(55)])).
ml_word('missing', adjective, forms(['missing']), demand([question_corpus(3), dataset(8)])).
ml_word('mission', noun, forms(['mission', 'missions']), demand([dataset(2)])).
ml_word('mission', verb, forms(['mission', 'missioned', 'missioning', 'missions']), demand([dataset(2)])).
ml_word('mistake', noun, forms(['mistake', 'mistakes']), demand([question_corpus(5), dataset(46)])).
ml_word('mistake', verb, forms(['mistake', 'mistaken', 'mistakes', 'mistaking', 'mistook']), demand([question_corpus(5), dataset(46)])).
ml_word('misunderstand', verb, forms(['misunderstand', 'misunderstanding', 'misunderstands', 'misunderstood']), demand([question_corpus(1)])).
ml_word('misunderstanding', noun, forms(['misunderstanding', 'misunderstandings']), demand([question_corpus(3)])).
ml_word('mitchell', given_name, forms(['mitchell']), demand([dataset(28), supplement_class('given_name')])).
ml_word('mitten', noun, forms(['mitten', 'mittens']), demand([dataset(9)])).
ml_word('mix', verb, forms(['mix', 'mixed', 'mixes', 'mixing']), demand([question_corpus(3), dataset(30)])).
ml_word('mixed', adjective, forms(['mixed']), demand([question_corpus(1), dataset(24)])).
ml_word('mixture', noun, forms(['mixture', 'mixtures']), demand([question_corpus(1), dataset(8)])).
ml_word('ml', unit_abbreviation, forms(['ml']), demand([dataset(57), supplement_class('unit_abbreviation')])).
ml_word('mobile', noun, forms(['mobile', 'mobiles']), demand([dataset(2)])).
ml_word('mobile', adjective, forms(['mobile']), demand([dataset(2)])).
ml_word('mode', noun, forms(['mode', 'modes']), demand([questioning_paper_lexicon])).
ml_word('model', noun, forms(['model', 'models']), demand([question_corpus(3), dataset(33)])).
ml_word('model', verb, forms(['model', 'modeled', 'modeling', 'models']), demand([question_corpus(3), dataset(33)])).
ml_word('model', adjective, forms(['model']), demand([question_corpus(1), dataset(15)])).
ml_word('module', noun, forms(['module', 'modules']), demand([question_corpus(1)])).
ml_word('module', verb, forms(['module', 'moduled', 'modules', 'moduling']), demand([question_corpus(1)])).
ml_word('mom', noun, forms(['mom', 'moms']), demand([dataset(37), supplement_class('common_noun')])).
ml_word('moment', noun, forms(['moment', 'moments']), demand([question_corpus(1)])).
ml_word('momentum', noun, forms(['f', 'momenta', 'momentum', 'momentums']), demand([dataset(12)])).
ml_word('monday', noun, forms(['monday', 'mondays']), demand([dataset(93)])).
ml_word('money', noun, forms(['money', 'moneys']), demand([question_corpus(4), dataset(292)])).
ml_word('money', verb, forms(['money', 'moneyed', 'moneying', 'moneys']), demand([question_corpus(4), dataset(292)])).
ml_word('monkey', noun, forms(['monkey', 'monkeys']), demand([dataset(14)])).
ml_word('monkey', verb, forms(['monkey', 'monkeyed', 'monkeying', 'monkeys']), demand([dataset(14)])).
ml_word('monster', noun, forms(['monster', 'monsters']), demand([dataset(9)])).
ml_word('monster', verb, forms(['monster', 'monstered', 'monstering', 'monsters']), demand([dataset(9)])).
ml_word('monster', adjective, forms(['monster']), demand([dataset(9)])).
ml_word('montero', noun, forms(['montero', 'monteros']), demand([dataset(5)])).
ml_word('month', noun, forms(['month', 'months']), demand([dataset(355)])).
ml_word('monthly', noun, forms(['monthlies', 'monthly']), demand([dataset(29)])).
ml_word('monthly', adjective, forms(['monthly']), demand([dataset(29)])).
ml_word('monthly', adverb, forms(['monthly']), demand([dataset(29)])).
ml_word('moon', noun, forms(['moon', 'moons']), demand([dataset(27)])).
ml_word('moon', verb, forms(['moon', 'mooned', 'mooning', 'moons']), demand([dataset(27)])).
ml_word('more', noun, forms(['more', 'mores']), demand([dataset(4)])).
ml_word('more', verb, forms(['more', 'mored', 'mores', 'moring']), demand([dataset(4)])).
ml_word('morgan', noun, forms(['morgan', 'morgans']), demand([dataset(20)])).
ml_word('morning', adjective, forms(['morning']), demand([dataset(87)])).
ml_word('mosaic', noun, forms(['mosaic', 'mosaics']), demand([question_corpus(1)])).
ml_word('mosaic', adjective, forms(['mosaic']), demand([question_corpus(1)])).
ml_word('mosel', noun, forms(['mosel', 'mosels']), demand([dataset(7)])).
ml_word('mosel', verb, forms(['mosel']), demand([dataset(7)])).
ml_word('mosquito', noun, forms(['mosquito', 'mosquitoes', 'mosquitos']), demand([dataset(21)])).
ml_word('mother', noun, forms(['mother', 'mothers']), demand([dataset(87)])).
ml_word('mother', verb, forms(['mother', 'mothered', 'mothering', 'mothers']), demand([dataset(87)])).
ml_word('mother', adjective, forms(['mother']), demand([dataset(87)])).
ml_word('motion', noun, forms(['motion', 'motions']), demand([question_corpus(1)])).
ml_word('motion', verb, forms(['motion', 'motioned', 'motioning', 'motions']), demand([question_corpus(1)])).
ml_word('motorcycle', noun, forms(['motorcycle', 'motorcycles']), demand([dataset(14), supplement_class('common_noun')])).
ml_word('mountain', noun, forms(['mountain', 'mountains']), demand([dataset(20)])).
ml_word('mountain', adjective, forms(['mountain']), demand([dataset(20)])).
ml_word('mountaineer', noun, forms(['mountaineer', 'mountaineers']), demand([question_corpus(2)])).
ml_word('mountaineer', verb, forms(['mountaineer', 'mountaineered', 'mountaineering', 'mountaineers']), demand([question_corpus(2)])).
ml_word('mouthful', noun, forms(['mouthful', 'mouthfuls']), demand([dataset(2)])).
ml_word('move', noun, forms(['move', 'moves']), demand([question_corpus(4), dataset(19)])).
ml_word('move', verb, forms(['move', 'moved', 'moves', 'moving']), demand([question_corpus(7), dataset(30)])).
ml_word('movement', noun, forms(['movement', 'movements']), demand([question_corpus(1)])).
ml_word('mover', noun, forms(['mover', 'movers']), demand([question_corpus(1)])).
ml_word('movie', noun, forms(['movie', 'movies']), demand([dataset(154)])).
ml_word('moving', noun, forms(['moving', 'movings']), demand([question_corpus(3), dataset(6)])).
ml_word('moving', adjective, forms(['moving']), demand([question_corpus(3), dataset(6)])).
ml_word('mow', verb, forms(['mow', 'mowed', 'mowing', 'mows']), demand([dataset(12)])).
ml_word('mowing', noun, forms(['mowing', 'mowings']), demand([dataset(6)])).
ml_word('mph', unit_abbreviation, forms(['mph']), demand([dataset(29), supplement_class('unit_abbreviation')])).
ml_word('mr', honorific, forms(['mr']), demand([dataset(55), supplement_class('honorific')])).
ml_word('mrs', honorific, forms(['mrs']), demand([dataset(37), supplement_class('honorific')])).
ml_word('ms', honorific, forms(['ms']), demand([dataset(36), supplement_class('honorific')])).
ml_word('much', noun, forms(['much', 'muches']), demand([question_corpus(9), dataset(620)])).
ml_word('much', adjective, forms(['much']), demand([question_corpus(9), dataset(620)])).
ml_word('much', adverb, forms(['much']), demand([question_corpus(9), dataset(620)])).
ml_word('muffaletta', noun, forms(['muffaletta', 'muffalettas']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('mug', noun, forms(['mug', 'mugs']), demand([dataset(6)])).
ml_word('multi', adjective, forms(['multi']), demand([question_corpus(2), dataset(2), supplement_class('adjective')])).
ml_word('multiple', noun, forms(['multiple', 'multiples']), demand([question_corpus(10), dataset(1), questioning_paper_lexicon, webster_domain('math')])).
ml_word('multiple', adjective, forms(['multiple']), demand([question_corpus(6), dataset(1), questioning_paper_lexicon, webster_domain('math')])).
ml_word('multiplication', noun, forms(['multiplication', 'multiplications']), demand([question_corpus(16), dataset(1), questioning_paper_lexicon])).
ml_word('multiply', verb, forms(['multiplied', 'multiplies', 'multiply', 'multiplyed', 'multiplying']), demand([question_corpus(8), dataset(94)])).
ml_word('mum', noun, forms(['mum', 'mums']), demand([dataset(1)])).
ml_word('mum', adjective, forms(['mum']), demand([dataset(1)])).
ml_word('mum', interjection, forms(['mum']), demand([dataset(1)])).
ml_word('mushroom', noun, forms(['mushroom', 'mushrooms']), demand([dataset(22)])).
ml_word('mushroom', adjective, forms(['mushroom']), demand([dataset(5)])).
ml_word('music', noun, forms(['music', 'musics']), demand([dataset(10)])).
ml_word('musical', noun, forms(['musical', 'musicals']), demand([dataset(2)])).
ml_word('musical', adjective, forms(['musical']), demand([dataset(2)])).
ml_word('must', noun, forms(['must', 'musts']), demand([question_corpus(5), dataset(88)])).
ml_word('must', verb, forms(['must', 'musted', 'musting', 'musts']), demand([question_corpus(5), dataset(88)])).
ml_word('mustafa', given_name, forms(['mustafa']), demand([dataset(6), supplement_class('given_name')])).
ml_word('n', noun, forms(['n', 'print']), demand([dataset(2)])).
ml_word('nadia', given_name, forms(['nadia']), demand([dataset(6), supplement_class('given_name')])).
ml_word('nail', noun, forms(['nail', 'nails']), demand([dataset(9)])).
ml_word('nail', verb, forms(['nail', 'nailed', 'nailing', 'nails']), demand([dataset(9)])).
ml_word('name', noun, forms(['name', 'names']), demand([question_corpus(1)])).
ml_word('name', verb, forms(['name', 'named', 'names', 'naming']), demand([question_corpus(1), dataset(4)])).
ml_word('nancy', given_name, forms(['nancy']), demand([dataset(11), supplement_class('given_name')])).
ml_word('nap', noun, forms(['nap', 'naps']), demand([dataset(5)])).
ml_word('nap', verb, forms(['nap', 'naped', 'naping', 'napped', 'napping', 'naps']), demand([dataset(5)])).
ml_word('nate', given_name, forms(['nate']), demand([dataset(3), supplement_class('given_name')])).
ml_word('near', adjective, forms(['near', 'nearer', 'nearest']), demand([question_corpus(3), dataset(18)])).
ml_word('nearby', adjective, forms(['nearby']), demand([dataset(4), supplement_class('adjective')])).
ml_word('necessarily', adverb, forms(['necessarily']), demand([question_corpus(1)])).
ml_word('necessary', noun, forms(['necessaries', 'necessary']), demand([question_corpus(2)])).
ml_word('necessary', adjective, forms(['necessary']), demand([question_corpus(2)])).
ml_word('necklace', noun, forms(['necklace', 'necklaces']), demand([question_corpus(1), supplement_class('common_noun')])).
ml_word('need', noun, forms(['need', 'needs']), demand([question_corpus(27), dataset(781)])).
ml_word('need', verb, forms(['need', 'needed', 'needing', 'needs']), demand([question_corpus(31), dataset(823)])).
ml_word('need', adverb, forms(['need']), demand([question_corpus(26), dataset(290)])).
ml_word('needs', adverb, forms(['needs']), demand([question_corpus(1), dataset(491)])).
ml_word('negative', noun, forms(['negative', 'negatives']), demand([question_corpus(2), dataset(6), questioning_paper_lexicon])).
ml_word('negative', verb, forms(['negative', 'negatived', 'negatives', 'negativing']), demand([question_corpus(2), dataset(6), questioning_paper_lexicon])).
ml_word('negative', adjective, forms(['negative']), demand([question_corpus(2), dataset(6), questioning_paper_lexicon])).
ml_word('neighbor', noun, forms(['neighbor', 'neighbors']), demand([question_corpus(1), dataset(10)])).
ml_word('neighbor', verb, forms(['neighbor', 'neighbored', 'neighboring', 'neighbors']), demand([question_corpus(1), dataset(10)])).
ml_word('neighbor', adjective, forms(['neighbor']), demand([question_corpus(1), dataset(6)])).
ml_word('neighborhood', noun, forms(['neighborhood', 'neighborhoods']), demand([question_corpus(2), dataset(31)])).
ml_word('neil', given_name, forms(['neil']), demand([dataset(12), supplement_class('given_name')])).
ml_word('neptune', noun, forms(['neptune', 'neptunes']), demand([question_corpus(1)])).
ml_word('net', noun, forms(['net', 'nets']), demand([question_corpus(1), dataset(28)])).
ml_word('net', verb, forms(['net', 'neted', 'neting', 'nets', 'netted', 'netting']), demand([question_corpus(1), dataset(28)])).
ml_word('net', adjective, forms(['net']), demand([dataset(28)])).
ml_word('new', verb, forms(['new', 'newed', 'newing', 'news']), demand([question_corpus(10), dataset(250)])).
ml_word('new', adjective, forms(['new', 'newer', 'newest']), demand([question_corpus(10), dataset(250)])).
ml_word('new', adverb, forms(['new']), demand([question_corpus(10), dataset(250)])).
ml_word('newfound', adjective, forms(['newfound']), demand([dataset(2), supplement_class('adjective')])).
ml_word('newspaper', noun, forms(['newspaper', 'newspapers']), demand([dataset(34)])).
ml_word('next', adjective, forms(['next']), demand([question_corpus(15), dataset(89)])).
ml_word('next', adverb, forms(['next']), demand([question_corpus(15), dataset(89)])).
ml_word('ney', family_name, forms(['ney']), demand([dataset(4), supplement_class('family_name')])).
ml_word('nick', noun, forms(['nick', 'nicks']), demand([dataset(2)])).
ml_word('nick', verb, forms(['nick', 'nicked', 'nicking', 'nicks']), demand([dataset(2)])).
ml_word('nickel', noun, forms(['nickel', 'nickels']), demand([dataset(28)])).
ml_word('nicki', given_name, forms(['nicki']), demand([dataset(8), supplement_class('given_name')])).
ml_word('nicole', given_name, forms(['nicole']), demand([dataset(10), supplement_class('given_name')])).
ml_word('nida', given_name, forms(['nida']), demand([dataset(3), supplement_class('given_name')])).
ml_word('nigel', given_name, forms(['nigel']), demand([dataset(27), supplement_class('given_name')])).
ml_word('night', noun, forms(['night', 'nights']), demand([dataset(88)])).
ml_word('nile', noun, forms(['nile', 'niles']), demand([dataset(24)])).
ml_word('nilo', given_name, forms(['nilo']), demand([dataset(8), supplement_class('given_name')])).
ml_word('nine', noun, forms(['nine', 'nines']), demand([dataset(6)])).
ml_word('nine', adjective, forms(['nine']), demand([dataset(6)])).
ml_word('noah', noun, forms(['noah', 'noahs']), demand([question_corpus(4), dataset(8)])).
ml_word('non', adjective, forms(['non']), demand([question_corpus(2)])).
ml_word('none', noun, forms(['none', 'nones']), demand([dataset(5)])).
ml_word('none', adjective, forms(['none']), demand([dataset(5)])).
ml_word('none', pronoun, forms(['none']), demand([dataset(5)])).
ml_word('noodle', noun, forms(['noodle', 'noodles']), demand([question_corpus(1)])).
ml_word('noon', noun, forms(['noon', 'noons']), demand([dataset(2)])).
ml_word('noon', verb, forms(['noon', 'nooned', 'nooning', 'noons']), demand([dataset(2)])).
ml_word('noon', adjective, forms(['noon']), demand([dataset(2)])).
ml_word('norm', noun, forms(['norm', 'norms']), demand([question_corpus(8)])).
ml_word('normal', noun, forms(['normal', 'normals']), demand([dataset(60)])).
ml_word('normal', adjective, forms(['normal']), demand([dataset(60)])).
ml_word('normally', adverb, forms(['normally']), demand([dataset(28)])).
ml_word('north', noun, forms(['north', 'norths']), demand([dataset(4)])).
ml_word('north', verb, forms(['north', 'northed', 'northing', 'norths']), demand([dataset(4)])).
ml_word('north', adjective, forms(['north']), demand([dataset(4)])).
ml_word('north', adverb, forms(['north']), demand([dataset(4)])).
ml_word('northern', adjective, forms(['northern']), demand([dataset(2)])).
ml_word('nose', noun, forms(['nose', 'noses']), demand([dataset(61)])).
ml_word('nose', verb, forms(['nose', 'nosed', 'noses', 'nosing']), demand([dataset(61)])).
ml_word('notation', noun, forms(['notation', 'notations']), demand([question_corpus(1)])).
ml_word('note', noun, forms(['note', 'notes']), demand([question_corpus(3), dataset(174)])).
ml_word('note', verb, forms(['note', 'noted', 'notes', 'noting']), demand([question_corpus(3), dataset(174)])).
ml_word('notebook', noun, forms(['notebook', 'notebooks']), demand([question_corpus(1), dataset(21)])).
ml_word('nothing', noun, forms(['nothing', 'nothings']), demand([dataset(2)])).
ml_word('nothing', adverb, forms(['nothing']), demand([dataset(2)])).
ml_word('notice', noun, forms(['notice', 'notices']), demand([question_corpus(295), dataset(4)])).
ml_word('notice', verb, forms(['notice', 'noticed', 'notices', 'noticing']), demand([question_corpus(295), dataset(26)])).
ml_word('notify', verb, forms(['notified', 'notifies', 'notify', 'notifying']), demand([dataset(2)])).
ml_word('noun', noun, forms(['noun', 'nouns']), demand([question_corpus(1)])).
ml_word('novel', noun, forms(['novel', 'novels']), demand([dataset(18)])).
ml_word('novel', adjective, forms(['novel']), demand([dataset(3)])).
ml_word('november', noun, forms(['november', 'novembers']), demand([dataset(18)])).
ml_word('now', noun, forms(['now', 'nows']), demand([question_corpus(63), dataset(237)])).
ml_word('now', adjective, forms(['now']), demand([question_corpus(63), dataset(237)])).
ml_word('now', adverb, forms(['now']), demand([question_corpus(63), dataset(237)])).
ml_word('number', noun, forms(['number', 'numbers']), demand([question_corpus(178), dataset(1231), questioning_paper_lexicon])).
ml_word('number', verb, forms(['number', 'numbered', 'numbering', 'numbers']), demand([question_corpus(178), dataset(1237), questioning_paper_lexicon])).
ml_word('numbers', noun, forms(['numbers']), demand([question_corpus(66), dataset(2)])).
ml_word('numerator', noun, forms(['numerator', 'numerators']), demand([questioning_paper_lexicon])).
ml_word('numeric', noun, forms(['numeric', 'numerics']), demand([webster_domain('math')])).
ml_word('numeric', adjective, forms(['numeric']), demand([webster_domain('math')])).
ml_word('nut', noun, forms(['nut', 'nuts']), demand([dataset(44)])).
ml_word('nut', verb, forms(['nut', 'nuts', 'nutted', 'nutting']), demand([dataset(44)])).
ml_word('ny', adjective, forms(['ny']), demand([dataset(3)])).
ml_word('ny', adverb, forms(['ny']), demand([dataset(3)])).
ml_word('object', noun, forms(['object', 'objects']), demand([question_corpus(15), dataset(19)])).
ml_word('object', verb, forms(['object', 'objected', 'objecting', 'objects']), demand([question_corpus(15), dataset(19)])).
ml_word('object', adjective, forms(['object']), demand([question_corpus(3)])).
ml_word('oblique', noun, forms(['oblique', 'obliques']), demand([webster_domain('geom')])).
ml_word('oblique', verb, forms(['oblique', 'obliqued', 'obliques', 'obliquing']), demand([webster_domain('geom')])).
ml_word('oblique', adjective, forms(['oblique']), demand([webster_domain('geom')])).
ml_word('observation', noun, forms(['observation', 'observations']), demand([question_corpus(3)])).
ml_word('obtain', verb, forms(['obtain', 'obtained', 'obtaining', 'obtains']), demand([question_corpus(1), dataset(3)])).
ml_word('ocean', noun, forms(['ocean', 'oceans']), demand([question_corpus(1)])).
ml_word('ocean', adjective, forms(['ocean']), demand([question_corpus(1)])).
ml_word('october', noun, forms(['october', 'octobers']), demand([dataset(20)])).
ml_word('odd', adjective, forms(['odd', 'odder', 'oddest']), demand([dataset(5)])).
ml_word('odds', noun, forms(['odds']), demand([dataset(10), supplement_class('math_term')])).
ml_word('off', noun, forms(['off', 'offs']), demand([question_corpus(2), dataset(181)])).
ml_word('off', adjective, forms(['off']), demand([question_corpus(2), dataset(181)])).
ml_word('off', adverb, forms(['off']), demand([question_corpus(2), dataset(181)])).
ml_word('off', preposition, forms(['off']), demand([question_corpus(2), dataset(181)])).
ml_word('off', interjection, forms(['off']), demand([question_corpus(2), dataset(181)])).
ml_word('offer', noun, forms(['offer', 'offers']), demand([dataset(12)])).
ml_word('offer', verb, forms(['offer', 'offered', 'offering', 'offers']), demand([dataset(12)])).
ml_word('office', noun, forms(['office', 'offices']), demand([dataset(30)])).
ml_word('office', verb, forms(['office', 'officed', 'offices', 'officing']), demand([dataset(30)])).
ml_word('often', adjective, forms(['often', 'oftener', 'oftenest']), demand([question_corpus(2), dataset(6)])).
ml_word('often', adverb, forms(['often']), demand([question_corpus(2), dataset(6)])).
ml_word('oil', noun, forms(['oil', 'oils']), demand([dataset(24)])).
ml_word('oil', verb, forms(['oil', 'oiled', 'oiling', 'oils']), demand([dataset(24)])).
ml_word('olaf', given_name, forms(['olaf']), demand([dataset(12), supplement_class('given_name')])).
ml_word('old', noun, forms(['old', 'olds']), demand([question_corpus(1), dataset(371)])).
ml_word('old', adjective, forms(['old', 'older', 'oldest']), demand([question_corpus(1), dataset(393)])).
ml_word('olga', given_name, forms(['olga']), demand([dataset(27), supplement_class('given_name')])).
ml_word('oliver', noun, forms(['oliver', 'olivers']), demand([dataset(40)])).
ml_word('olivia', given_name, forms(['olivia']), demand([dataset(4), supplement_class('given_name')])).
ml_word('omar', given_name, forms(['omar']), demand([dataset(5), supplement_class('given_name')])).
ml_word('once', noun, forms(['once', 'onces']), demand([dataset(54)])).
ml_word('once', adverb, forms(['once']), demand([dataset(54)])).
ml_word('one', noun, forms(['one', 'ones']), demand([question_corpus(8), dataset(46), questioning_paper_lexicon])).
ml_word('one', verb, forms(['one', 'oned', 'ones', 'oning']), demand([question_corpus(8), dataset(46), questioning_paper_lexicon])).
ml_word('ones', adverb, forms(['ones']), demand([question_corpus(8), dataset(46), questioning_paper_lexicon])).
ml_word('online', adjective, forms(['online']), demand([dataset(4), supplement_class('adjective')])).
ml_word('only', adjective, forms(['only']), demand([question_corpus(8), dataset(219)])).
ml_word('only', adverb, forms(['only']), demand([question_corpus(8), dataset(219)])).
ml_word('only', conjunction, forms(['only']), demand([question_corpus(8), dataset(219)])).
ml_word('onto', preposition, forms(['onto']), demand([dataset(4)])).
ml_word('oomyapeck', given_name, forms(['oomyapeck']), demand([dataset(8), supplement_class('given_name')])).
ml_word('open', noun, forms(['open', 'opens']), demand([question_corpus(1), dataset(16)])).
ml_word('open', verb, forms(['open', 'opened', 'opening', 'opens']), demand([question_corpus(1), dataset(40)])).
ml_word('open', adjective, forms(['open']), demand([question_corpus(1), dataset(12)])).
ml_word('openai', named_entity, forms(['openai']), demand([dataset(2), supplement_class('named_entity')])).
ml_word('opening', noun, forms(['opening', 'openings']), demand([dataset(20)])).
ml_word('operate', verb, forms(['operate', 'operated', 'operates', 'operating']), demand([dataset(10)])).
ml_word('operation', noun, forms(['operation', 'operations']), demand([question_corpus(4)])).
ml_word('opportunity', noun, forms(['opportunities', 'opportunity']), demand([question_corpus(3)])).
ml_word('oppose', verb, forms(['oppose', 'opposed', 'opposes', 'opposing']), demand([dataset(5)])).
ml_word('opposite', noun, forms(['opposite', 'opposites']), demand([dataset(17)])).
ml_word('opposite', adjective, forms(['opposite']), demand([dataset(17)])).
ml_word('option', noun, forms(['option', 'options']), demand([question_corpus(2)])).
ml_word('orange', noun, forms(['orange', 'oranges']), demand([question_corpus(5), dataset(59)])).
ml_word('orange', adjective, forms(['orange']), demand([question_corpus(3), dataset(28)])).
ml_word('order', noun, forms(['order', 'orders']), demand([question_corpus(4), dataset(40)])).
ml_word('order', verb, forms(['order', 'ordered', 'ordering', 'orders']), demand([question_corpus(4), dataset(51)])).
ml_word('ordinary', noun, forms(['ordinaries', 'ordinary']), demand([dataset(8)])).
ml_word('ordinary', adjective, forms(['ordinary']), demand([dataset(8)])).
ml_word('ordinate', noun, forms(['ordinate', 'ordinates']), demand([webster_domain('geom')])).
ml_word('ordinate', verb, forms(['ordinate', 'ordinated', 'ordinates', 'ordinating']), demand([webster_domain('geom')])).
ml_word('ordinate', adjective, forms(['ordinate']), demand([webster_domain('geom')])).
ml_word('organization', noun, forms(['organization', 'organizations']), demand([question_corpus(1), dataset(2)])).
ml_word('organize', verb, forms(['organize', 'organized', 'organizes', 'organizing']), demand([dataset(4)])).
ml_word('original', noun, forms(['original', 'originals']), demand([question_corpus(8), dataset(83)])).
ml_word('original', adjective, forms(['original']), demand([question_corpus(8), dataset(83)])).
ml_word('originally', adverb, forms(['originally']), demand([dataset(32)])).
ml_word('orthotomy', noun, forms(['orthotomies', 'orthotomy']), demand([webster_domain('geom')])).
ml_word('oscar', given_name, forms(['oscar']), demand([dataset(6), supplement_class('given_name')])).
ml_word('otherwise', adverb, forms(['otherwise']), demand([dataset(2)])).
ml_word('ounce', noun, forms(['ounce', 'ounces']), demand([question_corpus(1), dataset(246)])).
ml_word('out', noun, forms(['out', 'outs']), demand([question_corpus(37), dataset(369)])).
ml_word('out', verb, forms(['out', 'outed', 'outing', 'outs']), demand([question_corpus(37), dataset(369)])).
ml_word('out', adverb, forms(['out']), demand([question_corpus(37), dataset(369)])).
ml_word('out', interjection, forms(['out']), demand([question_corpus(37), dataset(369)])).
ml_word('outbreak', noun, forms(['outbreak', 'outbreaks']), demand([dataset(6)])).
ml_word('outcome', noun, forms(['outcome', 'outcomes']), demand([question_corpus(4)])).
ml_word('outline', noun, forms(['outline', 'outlines']), demand([question_corpus(1)])).
ml_word('outline', verb, forms(['outline', 'outlined', 'outlines', 'outlining']), demand([question_corpus(1)])).
ml_word('output', noun, forms(['output', 'outputs']), demand([question_corpus(1)])).
ml_word('outrun', verb, forms(['outran', 'outrun', 'outrunning', 'outruns']), demand([dataset(2)])).
ml_word('outside', noun, forms(['outside', 'outsides']), demand([question_corpus(2), dataset(11)])).
ml_word('outside', adjective, forms(['outside']), demand([question_corpus(2), dataset(11)])).
ml_word('outside', adverb, forms(['outside']), demand([question_corpus(2), dataset(11)])).
ml_word('over', noun, forms(['over', 'overs']), demand([question_corpus(9), dataset(148)])).
ml_word('over', adjective, forms(['over']), demand([question_corpus(9), dataset(148)])).
ml_word('over', adverb, forms(['over']), demand([question_corpus(9), dataset(148)])).
ml_word('over', preposition, forms(['over']), demand([question_corpus(9), dataset(148)])).
ml_word('overall', adverb, forms(['overall']), demand([dataset(14)])).
ml_word('overflow', verb, forms(['overflow', 'overflowed', 'overflowing', 'overflows']), demand([dataset(3)])).
ml_word('overflowing', noun, forms(['overflowing', 'overflowings']), demand([dataset(3)])).
ml_word('overhead', adverb, forms(['overhead']), demand([dataset(2)])).
ml_word('overlap', noun, forms(['overlap', 'overlaps']), demand([question_corpus(2), dataset(2)])).
ml_word('overlap', verb, forms(['overlap', 'overlaped', 'overlaping', 'overlapped', 'overlapping', 'overlaps']), demand([question_corpus(2), dataset(2), supplement_class('corpus_verb')])).
ml_word('overtime', noun, forms(['overtime', 'overtimes']), demand([dataset(33)])).
ml_word('owe', verb, forms(['owe', 'owed', 'owes', 'owing']), demand([dataset(3)])).
ml_word('own', verb, forms(['own', 'owned', 'owning', 'owns']), demand([dataset(94)])).
ml_word('own', adjective, forms(['own']), demand([dataset(55)])).
ml_word('owner', noun, forms(['owner', 'owners']), demand([dataset(51)])).
ml_word('oz', unit_abbreviation, forms(['oz']), demand([dataset(14), supplement_class('unit_abbreviation')])).
ml_word('p', algebra_symbol, forms(['p']), demand([question_corpus(2), dataset(11), supplement_class('algebra_symbol')])).
ml_word('pablo', given_name, forms(['pablo']), demand([dataset(8), supplement_class('given_name')])).
ml_word('pace', noun, forms(['pace', 'paces']), demand([question_corpus(2), supplement_class('common_noun')])).
ml_word('pack', verb, forms(['pack', 'packed', 'packing', 'packs']), demand([question_corpus(1), dataset(88)])).
ml_word('package', noun, forms(['package', 'packages']), demand([dataset(106)])).
ml_word('package', verb, forms(['package', 'packaged', 'packages', 'packaging']), demand([dataset(106), supplement_class('corpus_verb')])).
ml_word('packet', noun, forms(['packet', 'packets']), demand([dataset(36)])).
ml_word('packet', verb, forms(['packet', 'packeted', 'packeting', 'packets']), demand([dataset(36)])).
ml_word('packing', noun, forms(['packing', 'packings']), demand([dataset(2)])).
ml_word('page', noun, forms(['page', 'pages']), demand([question_corpus(3), dataset(206)])).
ml_word('page', verb, forms(['page', 'paged', 'pages', 'paging']), demand([question_corpus(3), dataset(206)])).
ml_word('paige', given_name, forms(['paige']), demand([dataset(7), supplement_class('given_name')])).
ml_word('pain', noun, forms(['pain', 'pains']), demand([dataset(4)])).
ml_word('pain', verb, forms(['pain', 'pained', 'paining', 'pains']), demand([dataset(4)])).
ml_word('paint', noun, forms(['paint', 'paints']), demand([question_corpus(1), dataset(55)])).
ml_word('paint', verb, forms(['paint', 'painted', 'painting', 'paints']), demand([question_corpus(2), dataset(76)])).
ml_word('painted', adjective, forms(['painted']), demand([dataset(8)])).
ml_word('painter', noun, forms(['painter', 'painters']), demand([dataset(4)])).
ml_word('painting', noun, forms(['painting', 'paintings']), demand([question_corpus(1), dataset(37)])).
ml_word('pair', noun, forms(['pair', 'pairs']), demand([question_corpus(9), dataset(123)])).
ml_word('pair', verb, forms(['pair', 'paired', 'pairing', 'pairs']), demand([question_corpus(9), dataset(134)])).
ml_word('pairing', noun, forms(['pairing', 'pairings']), demand([dataset(2)])).
ml_word('palace', noun, forms(['palace', 'palaces']), demand([dataset(2)])).
ml_word('palm', noun, forms(['palm', 'palms']), demand([dataset(3)])).
ml_word('palm', verb, forms(['palm', 'palmed', 'palming', 'palms']), demand([dataset(3)])).
ml_word('palmer', noun, forms(['palmer', 'palmers']), demand([dataset(11)])).
ml_word('pam', noun, forms(['pam', 'pams']), demand([dataset(11)])).
ml_word('pan', noun, forms(['pan', 'pans']), demand([question_corpus(1), dataset(5)])).
ml_word('pan', verb, forms(['pan', 'paned', 'paning', 'panned', 'panning', 'pans']), demand([question_corpus(1), dataset(5)])).
ml_word('pancake', noun, forms(['pancake', 'pancakes']), demand([dataset(11)])).
ml_word('panda', noun, forms(['panda', 'pandas']), demand([dataset(13)])).
ml_word('pandemic', adjective, forms(['pandemic']), demand([dataset(8)])).
ml_word('pant', noun, forms(['pant', 'pants']), demand([dataset(9)])).
ml_word('pant', verb, forms(['pant', 'panted', 'panting', 'pants']), demand([dataset(9)])).
ml_word('pantry', noun, forms(['pantries', 'pantry']), demand([dataset(2)])).
ml_word('paper', noun, forms(['paper', 'papers']), demand([question_corpus(5), dataset(83)])).
ml_word('paper', verb, forms(['paper', 'papered', 'papering', 'papers']), demand([question_corpus(5), dataset(83)])).
ml_word('paper', adjective, forms(['paper']), demand([question_corpus(5), dataset(72)])).
ml_word('paperback', noun, forms(['paperback', 'paperbacks']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('parallel', noun, forms(['parallel', 'parallels']), demand([question_corpus(5), questioning_paper_lexicon])).
ml_word('parallel', verb, forms(['parallel', 'paralleled', 'paralleling', 'parallels']), demand([question_corpus(5), questioning_paper_lexicon])).
ml_word('parallel', adjective, forms(['parallel']), demand([question_corpus(5), questioning_paper_lexicon])).
ml_word('parallelogram', noun, forms(['parallelogram', 'parallelograms']), demand([question_corpus(5)])).
ml_word('parent', noun, forms(['parent', 'parents']), demand([dataset(40)])).
ml_word('parenthesis', noun, forms(['parentheses', 'parenthesis', 'parenthesises']), demand([question_corpus(3)])).
ml_word('paris', noun, forms(['paris', 'parises']), demand([dataset(7)])).
ml_word('park', noun, forms(['park', 'parks']), demand([question_corpus(3), dataset(30)])).
ml_word('park', verb, forms(['park', 'parked', 'parking', 'parks']), demand([question_corpus(5), dataset(67)])).
ml_word('parrot', noun, forms(['parrot', 'parrots']), demand([dataset(5)])).
ml_word('parrot', verb, forms(['parrot', 'parroted', 'parroting', 'parrots']), demand([dataset(5)])).
ml_word('parsley', noun, forms(['parsley', 'parsleys']), demand([dataset(38)])).
ml_word('part', noun, forms(['part', 'parts']), demand([question_corpus(31), dataset(71)])).
ml_word('part', verb, forms(['part', 'parted', 'parting', 'parts']), demand([question_corpus(31), dataset(71)])).
ml_word('part', adverb, forms(['part']), demand([question_corpus(13), dataset(41)])).
ml_word('partial', adjective, forms(['partial']), demand([question_corpus(2)])).
ml_word('participate', verb, forms(['participate', 'participated', 'participates', 'participating']), demand([question_corpus(1), dataset(5)])).
ml_word('participate', adjective, forms(['participate']), demand([question_corpus(1), dataset(5)])).
ml_word('particle', noun, forms(['particle', 'particles']), demand([dataset(13)])).
ml_word('particular', noun, forms(['particular', 'particulars']), demand([question_corpus(3), dataset(8)])).
ml_word('particular', adjective, forms(['particular']), demand([question_corpus(3), dataset(8)])).
ml_word('partition', noun, forms(['partition', 'partitions']), demand([question_corpus(1), questioning_paper_lexicon])).
ml_word('partition', verb, forms(['partition', 'partitioned', 'partitioning', 'partitions']), demand([question_corpus(2), questioning_paper_lexicon])).
ml_word('partitioning', noun, forms(['partitioning', 'partitionings']), demand([question_corpus(1), supplement_class('math_term')])).
ml_word('partner', noun, forms(['partner', 'partners']), demand([question_corpus(10), dataset(18)])).
ml_word('partner', verb, forms(['partner', 'partnered', 'partnering', 'partners']), demand([question_corpus(10), dataset(18)])).
ml_word('party', noun, forms(['parties', 'party']), demand([question_corpus(2), dataset(107)])).
ml_word('party', adjective, forms(['party']), demand([question_corpus(2), dataset(107)])).
ml_word('party', adverb, forms(['party']), demand([question_corpus(2), dataset(107)])).
ml_word('pass', noun, forms(['pass', 'passes']), demand([dataset(14)])).
ml_word('pass', verb, forms(['pass', 'passed', 'passes', 'passing']), demand([question_corpus(1), dataset(28)])).
ml_word('passenger', noun, forms(['passenger', 'passengers']), demand([dataset(20)])).
ml_word('passing', noun, forms(['passing', 'passings']), demand([dataset(8)])).
ml_word('passing', adjective, forms(['passing']), demand([dataset(8)])).
ml_word('passing', adverb, forms(['passing']), demand([dataset(8)])).
ml_word('past', noun, forms(['past', 'pasts']), demand([question_corpus(1), dataset(9)])).
ml_word('past', adjective, forms(['past']), demand([question_corpus(1), dataset(9)])).
ml_word('past', adverb, forms(['past']), demand([question_corpus(1), dataset(9)])).
ml_word('past', preposition, forms(['past']), demand([question_corpus(1), dataset(9)])).
ml_word('pastry', noun, forms(['pastries', 'pastry']), demand([dataset(48)])).
ml_word('pat', noun, forms(['pat', 'pats']), demand([dataset(4)])).
ml_word('pat', verb, forms(['pat', 'pats', 'patted', 'patting']), demand([dataset(4)])).
ml_word('pat', adjective, forms(['pat']), demand([dataset(4)])).
ml_word('pat', adverb, forms(['pat']), demand([dataset(4)])).
ml_word('path', noun, forms(['path', 'paths']), demand([question_corpus(1), dataset(6)])).
ml_word('path', verb, forms(['path', 'pathed', 'pathing', 'paths']), demand([question_corpus(1), dataset(6)])).
ml_word('patricia', given_name, forms(['patricia']), demand([dataset(8), supplement_class('given_name')])).
ml_word('pattern', noun, forms(['pattern', 'patterns']), demand([question_corpus(65), dataset(1)])).
ml_word('pattern', verb, forms(['pattern', 'patterned', 'patterning', 'patterns']), demand([question_corpus(65), dataset(1)])).
ml_word('patty', noun, forms(['patties', 'patty']), demand([dataset(2)])).
ml_word('paul', noun, forms(['paul', 'pauls']), demand([dataset(50)])).
ml_word('paw', noun, forms(['paw', 'paws']), demand([dataset(2)])).
ml_word('paw', verb, forms(['paw', 'pawed', 'pawing', 'paws']), demand([dataset(2)])).
ml_word('pawpaw', noun, forms(['pawpaw', 'pawpaws']), demand([dataset(3)])).
ml_word('pay', noun, forms(['pay', 'pays']), demand([question_corpus(7), dataset(253)])).
ml_word('pay', verb, forms(['paid', 'pay', 'paying', 'pays']), demand([question_corpus(8), dataset(373)])).
ml_word('payment', noun, forms(['payment', 'payments']), demand([dataset(32)])).
ml_word('peak', noun, forms(['peak', 'peaks']), demand([dataset(26)])).
ml_word('peak', verb, forms(['peak', 'peaked', 'peaking', 'peaks']), demand([dataset(26)])).
ml_word('peanut', noun, forms(['peanut', 'peanuts']), demand([dataset(64)])).
ml_word('pear', noun, forms(['pear', 'pears']), demand([dataset(3)])).
ml_word('pebble', noun, forms(['pebble', 'pebbles']), demand([dataset(21)])).
ml_word('pebble', verb, forms(['pebble', 'pebbled', 'pebbles', 'pebbling']), demand([dataset(21)])).
ml_word('peel', noun, forms(['peel', 'peels']), demand([dataset(35)])).
ml_word('peel', verb, forms(['peel', 'peeled', 'peeling', 'peels']), demand([dataset(50)])).
ml_word('pen', noun, forms(['pen', 'pens']), demand([dataset(18)])).
ml_word('pen', verb, forms(['pen', 'penned', 'penning', 'pens']), demand([dataset(18)])).
ml_word('pencil', noun, forms(['pencil', 'pencils']), demand([question_corpus(5), dataset(255)])).
ml_word('pencil', verb, forms(['pencil', 'penciled', 'penciling', 'pencils']), demand([question_corpus(5), dataset(255)])).
ml_word('pend', verb, forms(['pend', 'pended', 'pending', 'pends']), demand([dataset(2)])).
ml_word('pending', adjective, forms(['pending']), demand([dataset(2)])).
ml_word('pending', preposition, forms(['pending']), demand([dataset(2)])).
ml_word('penguin', noun, forms(['penguin', 'penguins']), demand([dataset(15)])).
ml_word('penny', noun, forms(['pence', 'pennies', 'penny']), demand([dataset(14)])).
ml_word('penny', adjective, forms(['penny']), demand([dataset(7)])).
ml_word('pension', noun, forms(['pension', 'pensions']), demand([dataset(48)])).
ml_word('pension', verb, forms(['pension', 'pensioned', 'pensioning', 'pensions']), demand([dataset(48)])).
ml_word('pentagon', noun, forms(['pentagon', 'pentagons']), demand([question_corpus(3)])).
ml_word('people', noun, forms(['people', 'peoples']), demand([question_corpus(14), dataset(548)])).
ml_word('people', verb, forms(['people', 'peopled', 'peoples', 'peopling']), demand([question_corpus(14), dataset(548)])).
ml_word('pepper', noun, forms(['pepper', 'peppers']), demand([dataset(12)])).
ml_word('pepper', verb, forms(['pepper', 'peppered', 'peppering', 'peppers']), demand([dataset(12)])).
ml_word('pepperoni', noun, forms(['pepperoni', 'pepperonis']), demand([dataset(16), supplement_class('common_noun')])).
ml_word('per', preposition, forms(['per']), demand([question_corpus(2), dataset(934)])).
ml_word('percent', noun, forms(['percent', 'percents']), demand([dataset(34), questioning_paper_lexicon, supplement_class('math_term')])).
ml_word('percentage', noun, forms(['percentage', 'percentages']), demand([question_corpus(7), dataset(34)])).
ml_word('percius', given_name, forms(['percius']), demand([dataset(3), supplement_class('given_name')])).
ml_word('percy', given_name, forms(['percy']), demand([dataset(3), supplement_class('given_name')])).
ml_word('perfect', noun, forms(['perfect', 'perfects']), demand([dataset(11)])).
ml_word('perfect', verb, forms(['perfect', 'perfected', 'perfecting', 'perfects']), demand([dataset(11)])).
ml_word('perfect', adjective, forms(['perfect']), demand([dataset(11)])).
ml_word('perform', verb, forms(['perform', 'performed', 'performing', 'performs']), demand([question_corpus(5), dataset(56)])).
ml_word('performance', noun, forms(['performance', 'performances']), demand([dataset(40)])).
ml_word('perfume', noun, forms(['perfume', 'perfumes']), demand([dataset(6)])).
ml_word('perfume', verb, forms(['perfume', 'perfumed', 'perfumes', 'perfuming']), demand([dataset(6)])).
ml_word('perimeter', noun, forms(['perimeter', 'perimeters']), demand([question_corpus(6), dataset(49), questioning_paper_lexicon])).
ml_word('period', noun, forms(['period', 'periods']), demand([dataset(6)])).
ml_word('period', verb, forms(['period', 'perioded', 'perioding', 'periods']), demand([dataset(6)])).
ml_word('permanent', adjective, forms(['permanent']), demand([dataset(6)])).
ml_word('permit', noun, forms(['permit', 'permits']), demand([dataset(14)])).
ml_word('permit', verb, forms(['permit', 'permited', 'permiting', 'permits', 'permitted', 'permitting']), demand([dataset(14)])).
ml_word('perpendicular', noun, forms(['perpendicular', 'perpendiculars']), demand([questioning_paper_lexicon])).
ml_word('perpendicular', adjective, forms(['perpendicular']), demand([questioning_paper_lexicon])).
ml_word('perry', noun, forms(['perries', 'perry']), demand([dataset(5)])).
ml_word('person', noun, forms(['person', 'persons']), demand([question_corpus(8), dataset(212)])).
ml_word('person', verb, forms(['person', 'personed', 'personing', 'persons']), demand([question_corpus(8), dataset(212)])).
ml_word('personalize', verb, forms(['personalize', 'personalized', 'personalizes', 'personalizing']), demand([dataset(2)])).
ml_word('pet', noun, forms(['pet', 'pets']), demand([question_corpus(2), dataset(36)])).
ml_word('pet', verb, forms(['pet', 'peted', 'peting', 'pets', 'petted', 'petting']), demand([question_corpus(2), dataset(36)])).
ml_word('pet', adjective, forms(['pet']), demand([question_corpus(1), dataset(25)])).
ml_word('petal', noun, forms(['petal', 'petals']), demand([dataset(9)])).
ml_word('peter', noun, forms(['peter', 'peters']), demand([dataset(27)])).
ml_word('peter', verb, forms(['peter', 'petered', 'petering', 'peters']), demand([dataset(27)])).
ml_word('pharmacy', noun, forms(['pharmacies', 'pharmacy']), demand([dataset(2)])).
ml_word('phoebe', noun, forms(['phoebe', 'phoebes']), demand([dataset(12)])).
ml_word('phone', noun, forms(['phone', 'phones']), demand([dataset(31)])).
ml_word('phone', verb, forms(['phone', 'phoned', 'phones', 'phoning']), demand([dataset(31)])).
ml_word('photo', noun, forms(['photo', 'photos']), demand([question_corpus(1), dataset(29)])).
ml_word('phrase', noun, forms(['phrase', 'phrases']), demand([question_corpus(7)])).
ml_word('phrase', verb, forms(['phrase', 'phrased', 'phrases', 'phrasing']), demand([question_corpus(7)])).
ml_word('physical', adjective, forms(['physical']), demand([dataset(6)])).
ml_word('physically', adverb, forms(['physically']), demand([dataset(6)])).
ml_word('pi', noun, forms(['pi', 'pis']), demand([dataset(2)])).
ml_word('pi', verb, forms(['pi', 'pied', 'pieing', 'pis']), demand([dataset(2)])).
ml_word('piano', noun, forms(['piano', 'pianos']), demand([dataset(4)])).
ml_word('piano', adjective, forms(['piano']), demand([dataset(4)])).
ml_word('piano', adverb, forms(['piano']), demand([dataset(4)])).
ml_word('pick', noun, forms(['pick', 'picks']), demand([question_corpus(3), dataset(73)])).
ml_word('pick', verb, forms(['pick', 'picked', 'picking', 'picks']), demand([question_corpus(4), dataset(117)])).
ml_word('picked', adjective, forms(['picked']), demand([question_corpus(1), dataset(27)])).
ml_word('picking', noun, forms(['picking', 'pickings']), demand([dataset(17)])).
ml_word('picking', adjective, forms(['picking']), demand([dataset(17)])).
ml_word('picnic', noun, forms(['picnic', 'picnics']), demand([dataset(4)])).
ml_word('picnic', verb, forms(['picnic', 'picnicked', 'picnicking', 'picnics']), demand([dataset(4)])).
ml_word('picture', noun, forms(['picture', 'pictures']), demand([question_corpus(25), dataset(9)])).
ml_word('picture', verb, forms(['picture', 'pictured', 'pictures', 'picturing']), demand([question_corpus(26), dataset(9)])).
ml_word('pictured', adjective, forms(['pictured']), demand([question_corpus(1)])).
ml_word('pie', noun, forms(['pie', 'pies']), demand([dataset(92)])).
ml_word('pie', verb, forms(['pie', 'pied', 'pies', 'pying']), demand([dataset(92)])).
ml_word('piece', noun, forms(['piece', 'pieces']), demand([question_corpus(8), dataset(100)])).
ml_word('piece', verb, forms(['piece', 'pieced', 'pieces', 'piecing']), demand([question_corpus(8), dataset(100)])).
ml_word('piggy', adjective, forms(['piggy']), demand([dataset(24), supplement_class('adjective')])).
ml_word('pile', noun, forms(['pile', 'piles']), demand([dataset(25)])).
ml_word('pile', verb, forms(['pile', 'piled', 'piles', 'piling']), demand([dataset(25)])).
ml_word('piles', noun, forms(['piles']), demand([dataset(1)])).
ml_word('pill', noun, forms(['pill', 'pills']), demand([dataset(28)])).
ml_word('pill', verb, forms(['pill', 'pilled', 'pilling', 'pills']), demand([dataset(28)])).
ml_word('pillar', noun, forms(['pillar', 'pillars']), demand([dataset(7)])).
ml_word('pilot', noun, forms(['pilot', 'pilots']), demand([dataset(2)])).
ml_word('pilot', verb, forms(['pilot', 'piloted', 'piloting', 'pilots']), demand([dataset(2)])).
ml_word('pima', given_name, forms(['pima']), demand([dataset(3), supplement_class('given_name')])).
ml_word('pipe', noun, forms(['pipe', 'pipes']), demand([dataset(3)])).
ml_word('pipe', verb, forms(['pipe', 'piped', 'pipes', 'piping']), demand([dataset(3)])).
ml_word('pirate', noun, forms(['pirate', 'pirates']), demand([dataset(14)])).
ml_word('pirate', verb, forms(['pirate', 'pirated', 'pirates', 'pirating']), demand([dataset(14)])).
ml_word('pizza', noun, forms(['pizza', 'pizzas']), demand([dataset(46), supplement_class('common_noun')])).
ml_word('place', noun, forms(['place', 'places']), demand([question_corpus(25), dataset(61), questioning_paper_lexicon])).
ml_word('place', verb, forms(['place', 'placed', 'places', 'placing']), demand([question_corpus(28), dataset(76), questioning_paper_lexicon])).
ml_word('placement', noun, forms(['placement', 'placements']), demand([question_corpus(1)])).
ml_word('plain', noun, forms(['plain', 'plains']), demand([dataset(10)])).
ml_word('plain', verb, forms(['plain', 'plained', 'plaining', 'plains']), demand([dataset(10)])).
ml_word('plain', adjective, forms(['plain', 'plainer', 'plainest']), demand([dataset(2)])).
ml_word('plain', adverb, forms(['plain']), demand([dataset(2)])).
ml_word('plan', noun, forms(['plan', 'plans']), demand([question_corpus(5), dataset(41)])).
ml_word('plan', verb, forms(['plan', 'planned', 'planning', 'plans']), demand([question_corpus(6), dataset(53)])).
ml_word('plane', noun, forms(['plane', 'planes']), demand([question_corpus(5), dataset(13)])).
ml_word('plane', verb, forms(['plane', 'planed', 'planes', 'planing']), demand([question_corpus(5), dataset(13)])).
ml_word('plane', adjective, forms(['plane']), demand([question_corpus(5), dataset(13)])).
ml_word('plant', noun, forms(['plant', 'plants']), demand([question_corpus(4), dataset(60)])).
ml_word('plant', verb, forms(['plant', 'planted', 'planting', 'plants']), demand([question_corpus(5), dataset(78)])).
ml_word('planted', adjective, forms(['planted']), demand([question_corpus(1), dataset(16)])).
ml_word('planter', noun, forms(['planter', 'planters']), demand([dataset(7)])).
ml_word('planting', noun, forms(['planting', 'plantings']), demand([dataset(2)])).
ml_word('plastic', noun, forms(['plastic', 'plastics']), demand([dataset(18), supplement_class('common_noun')])).
ml_word('plastic', adjective, forms(['plastic']), demand([dataset(18)])).
ml_word('plate', noun, forms(['plate', 'plates']), demand([question_corpus(2), dataset(48)])).
ml_word('plate', verb, forms(['plate', 'plated', 'plates', 'plating']), demand([question_corpus(2), dataset(48)])).
ml_word('plateau', noun, forms(['f', 'plateau', 'plateaus', 'plateaux']), demand([dataset(12)])).
ml_word('play', noun, forms(['play', 'plays']), demand([question_corpus(5), dataset(62)])).
ml_word('play', verb, forms(['play', 'played', 'playing', 'plays']), demand([question_corpus(8), dataset(106)])).
ml_word('player', noun, forms(['player', 'players']), demand([dataset(48)])).
ml_word('playground', noun, forms(['playground', 'playgrounds']), demand([question_corpus(1)])).
ml_word('playoff', noun, forms(['playoff', 'playoffs']), demand([dataset(7), supplement_class('common_noun')])).
ml_word('please', verb, forms(['please', 'pleased', 'pleases', 'pleasing']), demand([dataset(2)])).
ml_word('pleased', adjective, forms(['pleased']), demand([dataset(2)])).
ml_word('plot', noun, forms(['plot', 'plots']), demand([question_corpus(18), dataset(9)])).
ml_word('plot', verb, forms(['plot', 'ploted', 'ploting', 'plots', 'plotted', 'plotting']), demand([question_corpus(20), dataset(9)])).
ml_word('pluck', noun, forms(['pluck', 'plucks']), demand([dataset(2)])).
ml_word('pluck', verb, forms(['pluck', 'plucked', 'plucking', 'plucks']), demand([dataset(2)])).
ml_word('plug', noun, forms(['plug', 'plugs']), demand([dataset(19)])).
ml_word('plug', verb, forms(['plug', 'plugged', 'plugging', 'plugs']), demand([dataset(19)])).
ml_word('plurality', noun, forms(['pluralities', 'plurality']), demand([question_corpus(1)])).
ml_word('plus', adjective, forms(['plus']), demand([dataset(25)])).
ml_word('pm', abbreviation, forms(['pm']), demand([dataset(8), supplement_class('abbreviation')])).
ml_word('pocket', noun, forms(['pocket', 'pockets']), demand([question_corpus(1), dataset(18)])).
ml_word('pocket', verb, forms(['pocket', 'pocketed', 'pocketing', 'pockets']), demand([question_corpus(1), dataset(18)])).
ml_word('poetry', noun, forms(['poetries', 'poetry']), demand([dataset(2)])).
ml_word('point', noun, forms(['point', 'points']), demand([question_corpus(18), dataset(105)])).
ml_word('point', verb, forms(['point', 'pointed', 'pointing', 'points']), demand([question_corpus(18), dataset(105)])).
ml_word('poison', verb, forms(['poison', 'poisoned', 'poisoning', 'poisons']), demand([dataset(8)])).
ml_word('poisonous', adjective, forms(['poisonous']), demand([dataset(2)])).
ml_word('pokemon', named_entity, forms(['pokemon']), demand([dataset(10), supplement_class('named_entity')])).
ml_word('police', noun, forms(['police', 'polices']), demand([dataset(8)])).
ml_word('police', verb, forms(['police', 'policed', 'polices', 'policing']), demand([dataset(8)])).
ml_word('poll', noun, forms(['poll', 'polls']), demand([dataset(8)])).
ml_word('poll', verb, forms(['poll', 'polled', 'polling', 'polls']), demand([dataset(11)])).
ml_word('polled', adjective, forms(['polled']), demand([dataset(3)])).
ml_word('polly', noun, forms(['pollies', 'polly']), demand([dataset(14)])).
ml_word('polygon', noun, forms(['polygon', 'polygons']), demand([question_corpus(3)])).
ml_word('polyhedron', noun, forms(['polyhedra', 'polyhedron', 'polyhedrons']), demand([question_corpus(1)])).
ml_word('pond', noun, forms(['pond', 'ponds']), demand([dataset(16)])).
ml_word('pond', verb, forms(['pond', 'ponded', 'ponding', 'ponds']), demand([dataset(16)])).
ml_word('poodle', noun, forms(['poodle', 'poodles']), demand([dataset(18)])).
ml_word('pool', noun, forms(['pool', 'pools']), demand([dataset(81)])).
ml_word('pool', verb, forms(['pool', 'pooled', 'pooling', 'pools']), demand([dataset(81)])).
ml_word('popcorn', noun, forms(['popcorn']), demand([question_corpus(1), dataset(56), supplement_class('common_noun')])).
ml_word('popular', adjective, forms(['popular']), demand([dataset(4)])).
ml_word('population', noun, forms(['population', 'populations']), demand([question_corpus(5), dataset(4)])).
ml_word('porch', noun, forms(['porch', 'porches']), demand([dataset(10)])).
ml_word('portable', adjective, forms(['portable']), demand([dataset(3)])).
ml_word('portion', noun, forms(['portion', 'portions']), demand([dataset(4)])).
ml_word('portion', verb, forms(['portion', 'portioned', 'portioning', 'portions']), demand([dataset(4)])).
ml_word('position', noun, forms(['position', 'positions']), demand([dataset(2)])).
ml_word('position', verb, forms(['position', 'positioned', 'positioning', 'positions']), demand([dataset(2)])).
ml_word('positive', noun, forms(['positive', 'positives']), demand([question_corpus(2), dataset(4), questioning_paper_lexicon])).
ml_word('positive', adjective, forms(['positive']), demand([question_corpus(2), dataset(4), questioning_paper_lexicon])).
ml_word('possible', adjective, forms(['possible']), demand([question_corpus(10), dataset(17)])).
ml_word('possibly', adverb, forms(['possibly']), demand([question_corpus(1)])).
ml_word('post', noun, forms(['post', 'posts']), demand([dataset(80)])).
ml_word('post', verb, forms(['post', 'posted', 'posting', 'posts']), demand([dataset(80)])).
ml_word('post', adjective, forms(['post']), demand([dataset(80)])).
ml_word('post', adverb, forms(['post']), demand([dataset(80)])).
ml_word('poster', noun, forms(['poster', 'posters']), demand([dataset(19)])).
ml_word('pot', noun, forms(['pot', 'pots']), demand([dataset(17)])).
ml_word('pot', verb, forms(['pot', 'poted', 'poting', 'pots', 'potted', 'potting']), demand([dataset(17)])).
ml_word('potato', noun, forms(['potato', 'potatoes', 'potatos']), demand([question_corpus(1), dataset(120)])).
ml_word('pound', noun, forms(['pound', 'pounds']), demand([question_corpus(3), dataset(622)])).
ml_word('pound', verb, forms(['pound', 'pounded', 'pounding', 'pounds']), demand([question_corpus(3), dataset(622)])).
ml_word('pour', noun, forms(['pour', 'pours']), demand([dataset(13)])).
ml_word('pour', verb, forms(['pour', 'poured', 'pouring', 'pours']), demand([question_corpus(1), dataset(25)])).
ml_word('pour', adjective, forms(['pour']), demand([dataset(1)])).
ml_word('power', noun, forms(['power', 'powers']), demand([question_corpus(2), dataset(2)])).
ml_word('practice', noun, forms(['practice', 'practices']), demand([question_corpus(1), dataset(13)])).
ml_word('practice', verb, forms(['practice', 'practiced', 'practices', 'practicing']), demand([question_corpus(1), dataset(41)])).
ml_word('practiced', adjective, forms(['practiced']), demand([dataset(12)])).
ml_word('practise', verb, forms(['practise', 'practised', 'practises', 'practising']), demand([dataset(2)])).
ml_word('precise', adjective, forms(['precise']), demand([question_corpus(2)])).
ml_word('predict', noun, forms(['predict', 'predicts']), demand([question_corpus(1)])).
ml_word('predict', verb, forms(['predict', 'predicted', 'predicting', 'predicts']), demand([question_corpus(2)])).
ml_word('prediction', noun, forms(['prediction', 'predictions']), demand([question_corpus(2)])).
ml_word('prefer', verb, forms(['prefer', 'preferred', 'preferring', 'prefers']), demand([question_corpus(1), dataset(9)])).
ml_word('preferable', adjective, forms(['preferable']), demand([question_corpus(1)])).
ml_word('preference', noun, forms(['preference', 'preferences']), demand([dataset(1)])).
ml_word('premise', noun, forms(['premise', 'premises']), demand([dataset(2)])).
ml_word('premise', verb, forms(['premise', 'premised', 'premises', 'premising']), demand([dataset(2)])).
ml_word('prep', verb, forms(['prep', 'prepped', 'prepping', 'preps']), demand([dataset(20), supplement_class('corpus_verb')])).
ml_word('preparation', noun, forms(['preparation', 'preparations']), demand([dataset(10)])).
ml_word('prepare', noun, forms(['prepare', 'prepares']), demand([question_corpus(4), dataset(10)])).
ml_word('prepare', verb, forms(['prepare', 'prepares', 'preparing']), demand([question_corpus(4), dataset(34)])).
ml_word('prepared', adjective, forms(['prepared']), demand([dataset(28)])).
ml_word('prescription', noun, forms(['prescription', 'prescriptions']), demand([dataset(4)])).
ml_word('present', noun, forms(['present', 'presents']), demand([dataset(38)])).
ml_word('present', verb, forms(['present', 'presented', 'presenting', 'presents']), demand([dataset(38)])).
ml_word('present', adjective, forms(['present']), demand([dataset(20)])).
ml_word('president', noun, forms(['president', 'presidents']), demand([dataset(2)])).
ml_word('president', adjective, forms(['president']), demand([dataset(2)])).
ml_word('press', noun, forms(['press', 'presses']), demand([dataset(2)])).
ml_word('press', verb, forms(['press', 'pressed', 'presses', 'pressing']), demand([dataset(2)])).
ml_word('previous', adjective, forms(['previous']), demand([question_corpus(4), dataset(31)])).
ml_word('previously', adverb, forms(['previously']), demand([dataset(13)])).
ml_word('price', noun, forms(['price', 'prices']), demand([question_corpus(6), dataset(125)])).
ml_word('price', verb, forms(['price', 'priced', 'prices', 'pricing']), demand([question_corpus(6), dataset(127)])).
ml_word('priced', adjective, forms(['priced']), demand([dataset(2)])).
ml_word('principal', noun, forms(['principal', 'principals']), demand([dataset(4)])).
ml_word('principal', adjective, forms(['principal']), demand([dataset(4)])).
ml_word('prior', noun, forms(['prior', 'priors']), demand([question_corpus(3)])).
ml_word('prior', adjective, forms(['prior']), demand([question_corpus(3)])).
ml_word('prism', noun, forms(['prism', 'prisms']), demand([question_corpus(17)])).
ml_word('priya', given_name, forms(['priya']), demand([question_corpus(2), supplement_class('given_name')])).
ml_word('probability', noun, forms(['probabilities', 'probability']), demand([question_corpus(2), dataset(8)])).
ml_word('probably', adverb, forms(['probably']), demand([question_corpus(1)])).
ml_word('problem', noun, forms(['problem', 'problems']), demand([question_corpus(71), dataset(90)])).
ml_word('procedure', noun, forms(['procedure', 'procedures']), demand([dataset(2)])).
ml_word('process', noun, forms(['process', 'processes']), demand([question_corpus(4), dataset(15)])).
ml_word('produce', noun, forms(['produce', 'produces']), demand([question_corpus(1), dataset(34)])).
ml_word('produce', verb, forms(['produce', 'produced', 'produces', 'producing']), demand([question_corpus(3), dataset(61)])).
ml_word('product', noun, forms(['product', 'products']), demand([question_corpus(25), dataset(8), questioning_paper_lexicon])).
ml_word('product', verb, forms(['product', 'producted', 'producting', 'products']), demand([question_corpus(25), dataset(8), questioning_paper_lexicon])).
ml_word('production', noun, forms(['production', 'productions']), demand([dataset(42)])).
ml_word('productive', adjective, forms(['productive']), demand([question_corpus(1)])).
ml_word('professional', noun, forms(['professional', 'professionals']), demand([dataset(8)])).
ml_word('professional', adjective, forms(['professional']), demand([dataset(1)])).
ml_word('profit', noun, forms(['profit', 'profits']), demand([dataset(130)])).
ml_word('profit', verb, forms(['profit', 'profited', 'profiting', 'profits']), demand([dataset(130)])).
ml_word('program', noun, forms(['program', 'programs']), demand([dataset(2)])).
ml_word('progress', noun, forms(['progress', 'progresses']), demand([question_corpus(1), dataset(4)])).
ml_word('progress', verb, forms(['progress', 'progressed', 'progressing', 'progresss']), demand([question_corpus(1), dataset(4), supplement_class('corpus_verb')])).
ml_word('progression', noun, forms(['progression', 'progressions']), demand([dataset(2)])).
ml_word('project', noun, forms(['project', 'projects']), demand([question_corpus(1), dataset(7)])).
ml_word('project', verb, forms(['project', 'projected', 'projecting', 'projects']), demand([question_corpus(1), dataset(7)])).
ml_word('promote', verb, forms(['promote', 'promoted', 'promotes', 'promoting']), demand([question_corpus(2)])).
ml_word('promotion', noun, forms(['promotion', 'promotions']), demand([dataset(5)])).
ml_word('promotional', adjective, forms(['promotional']), demand([dataset(7), supplement_class('adjective')])).
ml_word('prompt', noun, forms(['prompt', 'prompts']), demand([question_corpus(1)])).
ml_word('prompt', verb, forms(['prompt', 'prompted', 'prompting', 'prompts']), demand([question_corpus(1)])).
ml_word('property', noun, forms(['properties', 'property']), demand([question_corpus(1), dataset(10)])).
ml_word('property', verb, forms(['propertied', 'properties', 'property', 'propertying']), demand([question_corpus(1), dataset(10)])).
ml_word('proportion', noun, forms(['proportion', 'proportions']), demand([question_corpus(1), dataset(27)])).
ml_word('proportion', verb, forms(['proportion', 'proportioned', 'proportioning', 'proportions']), demand([question_corpus(1), dataset(27)])).
ml_word('proportional', noun, forms(['proportional', 'proportionals']), demand([question_corpus(7), dataset(1), questioning_paper_lexicon])).
ml_word('proportional', adjective, forms(['proportional']), demand([question_corpus(7), dataset(1), questioning_paper_lexicon])).
ml_word('proportionality', noun, forms(['proportionalities', 'proportionality']), demand([question_corpus(2)])).
ml_word('proposal', noun, forms(['proposal', 'proposals']), demand([question_corpus(1)])).
ml_word('propose', noun, forms(['propose', 'proposes']), demand([dataset(5)])).
ml_word('propose', verb, forms(['propose', 'proposed', 'proposes', 'proposing']), demand([dataset(5)])).
ml_word('prove', verb, forms(['prove', 'proved', 'proves', 'proving']), demand([question_corpus(1)])).
ml_word('provide', verb, forms(['provide', 'provided', 'provides', 'providing']), demand([question_corpus(1), dataset(4)])).
ml_word('pug', noun, forms(['pug', 'pugs']), demand([dataset(13)])).
ml_word('pug', verb, forms(['pug', 'pugged', 'pugging', 'pugs']), demand([dataset(13)])).
ml_word('pull', verb, forms(['pull', 'pulled', 'pulling', 'pulls']), demand([dataset(12)])).
ml_word('pumpkin', noun, forms(['pumpkin', 'pumpkins']), demand([question_corpus(1), dataset(55)])).
ml_word('puppy', noun, forms(['puppies', 'puppy']), demand([dataset(16)])).
ml_word('puppy', verb, forms(['puppied', 'puppies', 'puppy', 'puppying']), demand([dataset(16)])).
ml_word('purchase', verb, forms(['purchase', 'purchased', 'purchases', 'purchasing']), demand([question_corpus(1), dataset(75)])).
ml_word('purple', noun, forms(['purple', 'purples']), demand([question_corpus(1), dataset(3)])).
ml_word('purple', verb, forms(['purple', 'purpled', 'purples', 'purpling']), demand([question_corpus(1), dataset(3)])).
ml_word('purple', adjective, forms(['purple']), demand([question_corpus(1), dataset(3)])).
ml_word('purpose', noun, forms(['purpose', 'purposes']), demand([dataset(2)])).
ml_word('purpose', verb, forms(['purpose', 'purposed', 'purposes', 'purposing']), demand([dataset(2)])).
ml_word('purse', noun, forms(['purse', 'purses']), demand([dataset(8)])).
ml_word('purse', verb, forms(['purse', 'pursed', 'purses', 'pursing']), demand([dataset(8)])).
ml_word('push', noun, forms(['push', 'pushes']), demand([dataset(33)])).
ml_word('push', verb, forms(['push', 'pushed', 'pushes', 'pushing']), demand([dataset(33)])).
ml_word('put', noun, forms(['put', 'puts']), demand([question_corpus(4), dataset(131)])).
ml_word('put', verb, forms(['put', 'puts', 'putting']), demand([question_corpus(4), dataset(133)])).
ml_word('putt', verb, forms(['putt', 'putted', 'putting', 'putts']), demand([dataset(2)])).
ml_word('putting', noun, forms(['putting', 'puttings']), demand([dataset(2)])).
ml_word('puzzle', noun, forms(['puzzle', 'puzzles']), demand([question_corpus(3), dataset(67)])).
ml_word('puzzle', verb, forms(['puzzle', 'puzzled', 'puzzles', 'puzzling']), demand([question_corpus(3), dataset(67)])).
ml_word('pyramid', noun, forms(['pyramid', 'pyramids']), demand([dataset(7)])).
ml_word('q', algebra_symbol, forms(['q']), demand([question_corpus(2), supplement_class('algebra_symbol')])).
ml_word('quadratics', noun, forms(['quadratics', 'quadraticses']), demand([webster_domain('alg')])).
ml_word('quadrilateral', noun, forms(['quadrilateral', 'quadrilaterals']), demand([question_corpus(7)])).
ml_word('quadrilateral', adjective, forms(['quadrilateral']), demand([question_corpus(2)])).
ml_word('quadruple', noun, forms(['quadruple', 'quadruples']), demand([dataset(3)])).
ml_word('quadruple', verb, forms(['quadruple', 'quadrupled', 'quadruples', 'quadrupling']), demand([dataset(3)])).
ml_word('quadruple', adjective, forms(['quadruple']), demand([dataset(3)])).
ml_word('quality', noun, forms(['qualities', 'quality']), demand([dataset(6)])).
ml_word('quantity', noun, forms(['quantities', 'quantity']), demand([question_corpus(3), dataset(8)])).
ml_word('quart', noun, forms(['quart', 'quarts']), demand([question_corpus(1), dataset(46)])).
ml_word('quarter', noun, forms(['quarter', 'quarters']), demand([question_corpus(1), dataset(51)])).
ml_word('quarter', verb, forms(['quarter', 'quartered', 'quartering', 'quarters']), demand([question_corpus(1), dataset(51)])).
ml_word('queenie', given_name, forms(['queenie']), demand([dataset(24), supplement_class('given_name')])).
ml_word('question', noun, forms(['question', 'questions']), demand([question_corpus(61), dataset(10)])).
ml_word('question', verb, forms(['question', 'questioned', 'questioning', 'questions']), demand([question_corpus(62), dataset(10)])).
ml_word('quick', noun, forms(['quick', 'quicks']), demand([question_corpus(1)])).
ml_word('quick', verb, forms(['quick', 'quicked', 'quicking', 'quicks']), demand([question_corpus(1)])).
ml_word('quick', adjective, forms(['quick', 'quicker', 'quickest']), demand([question_corpus(1), dataset(2)])).
ml_word('quick', adverb, forms(['quick']), demand([question_corpus(1)])).
ml_word('quickly', adverb, forms(['quickly']), demand([question_corpus(6)])).
ml_word('quilt', noun, forms(['quilt', 'quilts']), demand([question_corpus(1)])).
ml_word('quilt', verb, forms(['quilt', 'quilted', 'quilting', 'quilts']), demand([question_corpus(1)])).
ml_word('quit', noun, forms(['quit', 'quits']), demand([dataset(8)])).
ml_word('quit', verb, forms(['quit', 'quited', 'quiting', 'quits', 'quitting']), demand([dataset(8)])).
ml_word('quiz', noun, forms(['quiz', 'quizs', 'quizzes']), demand([dataset(7), supplement_class('common_noun')])).
ml_word('quiz', verb, forms(['quiz', 'quized', 'quizing', 'quizs', 'quizzed', 'quizzing']), demand([dataset(7)])).
ml_word('quotient', noun, forms(['quotient', 'quotients']), demand([question_corpus(9), questioning_paper_lexicon])).
ml_word('r', algebra_symbol, forms(['r']), demand([dataset(13), supplement_class('algebra_symbol')])).
ml_word('rabbit', noun, forms(['rabbit', 'rabbits']), demand([question_corpus(1), dataset(42), supplement_class('common_noun')])).
ml_word('race', noun, forms(['race', 'races']), demand([question_corpus(1), dataset(65)])).
ml_word('race', verb, forms(['race', 'raced', 'races', 'racing']), demand([question_corpus(1), dataset(75)])).
ml_word('racer', noun, forms(['racer', 'racers']), demand([dataset(55)])).
ml_word('rachel', given_name, forms(['rachel']), demand([dataset(27), supplement_class('given_name')])).
ml_word('radio', noun, forms(['radio', 'radios']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('radius', noun, forms(['radii', 'radius', 'radiuses']), demand([question_corpus(4), dataset(1)])).
ml_word('raft', verb, forms(['raft', 'rafted', 'rafting', 'rafts']), demand([dataset(2)])).
ml_word('rafting', noun, forms(['rafting', 'raftings']), demand([dataset(2)])).
ml_word('rail', noun, forms(['rail', 'rails']), demand([dataset(4)])).
ml_word('rail', verb, forms(['rail', 'railed', 'railing', 'rails']), demand([dataset(4)])).
ml_word('rain', noun, forms(['rain', 'rains']), demand([dataset(2)])).
ml_word('rain', verb, forms(['rain', 'rained', 'raining', 'rains']), demand([dataset(2)])).
ml_word('rainforest', noun, forms(['rainforest', 'rainforests']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('rais', noun, forms(['rais', 'raises']), demand([dataset(2)])).
ml_word('raise', verb, forms(['raise', 'raised', 'raises', 'raising']), demand([dataset(22)])).
ml_word('raised', adjective, forms(['raised']), demand([dataset(3)])).
ml_word('ralph', noun, forms(['ralph', 'ralphs']), demand([dataset(22)])).
ml_word('ramp', noun, forms(['ramp', 'ramps']), demand([dataset(6)])).
ml_word('ramp', verb, forms(['ramp', 'ramped', 'ramping', 'ramps']), demand([dataset(12)])).
ml_word('ran', noun, forms(['ran', 'rans']), demand([question_corpus(2), dataset(36)])).
ml_word('ranch', noun, forms(['ranch', 'ranches']), demand([dataset(18)])).
ml_word('ranch', verb, forms(['ranch', 'ranched', 'ranches', 'ranching']), demand([dataset(18)])).
ml_word('rancher', noun, forms(['rancher', 'ranchers']), demand([dataset(30), supplement_class('common_noun')])).
ml_word('randi', given_name, forms(['randi']), demand([dataset(14), supplement_class('given_name')])).
ml_word('random', noun, forms(['random', 'randoms']), demand([question_corpus(2), dataset(2)])).
ml_word('random', adjective, forms(['random']), demand([question_corpus(2), dataset(2)])).
ml_word('randy', given_name, forms(['randy']), demand([dataset(30), supplement_class('given_name')])).
ml_word('range', noun, forms(['range', 'ranges']), demand([dataset(20), questioning_paper_lexicon])).
ml_word('range', verb, forms(['range', 'ranged', 'ranges', 'ranging']), demand([dataset(30), questioning_paper_lexicon])).
ml_word('rank', verb, forms(['rank', 'ranked', 'ranking', 'ranks']), demand([question_corpus(1)])).
ml_word('raspberry', noun, forms(['raspberries', 'raspberry']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('rate', noun, forms(['rate', 'rates']), demand([question_corpus(6), dataset(75), questioning_paper_lexicon])).
ml_word('rate', verb, forms(['rate', 'rated', 'rates', 'rating']), demand([question_corpus(6), dataset(75), questioning_paper_lexicon])).
ml_word('rather', adjective, forms(['rather']), demand([question_corpus(5)])).
ml_word('rather', adverb, forms(['rather']), demand([question_corpus(5)])).
ml_word('ratio', noun, forms(['ratio', 'ratios']), demand([question_corpus(4), dataset(48), questioning_paper_lexicon])).
ml_word('ray', noun, forms(['ray', 'rays']), demand([dataset(23)])).
ml_word('ray', verb, forms(['ray', 'rayed', 'raying', 'rays']), demand([dataset(23)])).
ml_word('reach', noun, forms(['reach', 'reaches']), demand([dataset(82)])).
ml_word('reach', verb, forms(['reach', 'reached', 'reaches', 'reaching']), demand([dataset(90)])).
ml_word('react', verb, forms(['react', 'reacted', 'reacting', 'reacts']), demand([dataset(2)])).
ml_word('reaction', noun, forms(['reaction', 'reactions']), demand([question_corpus(1)])).
ml_word('read', noun, forms(['read', 'reads']), demand([question_corpus(2), dataset(186)])).
ml_word('read', verb, forms(['read', 'reading', 'reads']), demand([question_corpus(4), dataset(221)])).
ml_word('read', adjective, forms(['read']), demand([question_corpus(2), dataset(152)])).
ml_word('reading', noun, forms(['reading', 'readings']), demand([question_corpus(2), dataset(35)])).
ml_word('reading', adjective, forms(['reading']), demand([question_corpus(2), dataset(35)])).
ml_word('ready', noun, forms(['readies', 'ready']), demand([question_corpus(16), dataset(6)])).
ml_word('ready', verb, forms(['readied', 'readies', 'ready', 'readying']), demand([question_corpus(16), dataset(6)])).
ml_word('ready', adjective, forms(['readier', 'readiest', 'ready']), demand([question_corpus(16), dataset(6)])).
ml_word('ready', adverb, forms(['ready']), demand([question_corpus(16), dataset(6)])).
ml_word('real', noun, forms(['real', 'reals']), demand([question_corpus(2), dataset(2)])).
ml_word('real', adjective, forms(['real']), demand([question_corpus(2), dataset(2)])).
ml_word('realise', verb, forms(['realise', 'realised', 'realises', 'realising']), demand([dataset(2), supplement_class('corpus_verb')])).
ml_word('realize', verb, forms(['realize', 'realized', 'realizes', 'realizing']), demand([dataset(31)])).
ml_word('realizing', adjective, forms(['realizing']), demand([dataset(1)])).
ml_word('really', adverb, forms(['really']), demand([question_corpus(4), dataset(4)])).
ml_word('rearrange', verb, forms(['rearrange', 'rearranged', 'rearranges', 'rearranging']), demand([question_corpus(3)])).
ml_word('reason', noun, forms(['reason', 'reasons']), demand([question_corpus(10), dataset(17)])).
ml_word('reason', verb, forms(['reason', 'reasoned', 'reasoning', 'reasons']), demand([question_corpus(100), dataset(17)])).
ml_word('reasonable', adjective, forms(['reasonable']), demand([question_corpus(2)])).
ml_word('reasonable', adverb, forms(['reasonable']), demand([question_corpus(2)])).
ml_word('reasoning', noun, forms(['reasoning', 'reasonings']), demand([question_corpus(90)])).
ml_word('rebecca', given_name, forms(['rebecca']), demand([dataset(14), supplement_class('given_name')])).
ml_word('receive', verb, forms(['receive', 'received', 'receives', 'receiving']), demand([question_corpus(1), dataset(86)])).
ml_word('recent', adjective, forms(['recent']), demand([question_corpus(3), dataset(2)])).
ml_word('recently', adverb, forms(['recently']), demand([dataset(2)])).
ml_word('recipe', noun, forms(['recipe', 'recipes']), demand([question_corpus(1), dataset(6)])).
ml_word('recommend', verb, forms(['recommend', 'recommended', 'recommending', 'recommends']), demand([dataset(3), supplement_class('corpus_verb')])).
ml_word('recommendation', noun, forms(['recommendation', 'recommendations']), demand([dataset(1), supplement_class('common_noun')])).
ml_word('record', verb, forms(['record', 'recorded', 'recording', 'records']), demand([question_corpus(3), dataset(140)])).
ml_word('recover', verb, forms(['recover', 'recovered', 'recovering', 'recovers']), demand([dataset(5), supplement_class('corpus_verb')])).
ml_word('rectangle', noun, forms(['rectangle', 'rectangles']), demand([question_corpus(28), dataset(29), supplement_class('math_term')])).
ml_word('rectangle', adjective, forms(['rectangle']), demand([question_corpus(18), dataset(19)])).
ml_word('rectangular', adjective, forms(['rectangular']), demand([question_corpus(2), dataset(10), supplement_class('adjective')])).
ml_word('recycle', verb, forms(['recycle', 'recycled', 'recycles', 'recycling']), demand([question_corpus(1), dataset(22), supplement_class('corpus_verb')])).
ml_word('red', verb, forms(['red', 'reded', 'reding', 'reds']), demand([question_corpus(4), dataset(191)])).
ml_word('red', adjective, forms(['red', 'redder', 'reddest']), demand([question_corpus(4), dataset(191)])).
ml_word('redeem', verb, forms(['redeem', 'redeemed', 'redeeming', 'redeems']), demand([dataset(8), supplement_class('corpus_verb')])).
ml_word('redo', verb, forms(['redid', 'redo', 'redoes', 'redoing', 'redone']), demand([question_corpus(4), supplement_class('corpus_verb')])).
ml_word('reduce', verb, forms(['reduce', 'reduced', 'reduces', 'reducing']), demand([dataset(28), supplement_class('corpus_verb')])).
ml_word('reduction', noun, forms(['reduction', 'reductions']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('refer', verb, forms(['refer', 'refered', 'refering', 'referred', 'referring', 'refers']), demand([question_corpus(1), supplement_class('corpus_verb')])).
ml_word('refill', verb, forms(['refill', 'refilled', 'refilling', 'refills']), demand([dataset(18), supplement_class('corpus_verb')])).
ml_word('reflect', verb, forms(['reflect', 'reflected', 'reflecting', 'reflects']), demand([question_corpus(2), supplement_class('corpus_verb')])).
ml_word('reflected', adjective, forms(['reflected']), demand([question_corpus(1)])).
ml_word('reflecting', adjective, forms(['reflecting']), demand([question_corpus(1)])).
ml_word('reflection', noun, forms(['reflection', 'reflections']), demand([questioning_paper_lexicon, supplement_class('math_term')])).
ml_word('refuel', verb, forms(['refuel', 'refueled', 'refueling', 'refuels']), demand([dataset(4), supplement_class('corpus_verb')])).
ml_word('refund', verb, forms(['refund', 'refunded', 'refunding', 'refunds']), demand([dataset(1), supplement_class('corpus_verb')])).
ml_word('refuse', verb, forms(['refuse', 'refused', 'refuses', 'refusing']), demand([dataset(6)])).
ml_word('regardless', adjective, forms(['regardless']), demand([dataset(2)])).
ml_word('reggie', given_name, forms(['reggie']), demand([dataset(18), supplement_class('given_name')])).
ml_word('region', noun, forms(['region', 'regions']), demand([question_corpus(7), dataset(2), supplement_class('math_term')])).
ml_word('register', verb, forms(['register', 'registered', 'registering', 'registers']), demand([dataset(8)])).
ml_word('regroup', verb, forms(['regroup', 'regrouped', 'regrouping', 'regroups']), demand([questioning_paper_lexicon, supplement_class('corpus_verb')])).
ml_word('regular', adjective, forms(['regular']), demand([dataset(50), supplement_class('adjective')])).
ml_word('rehana', given_name, forms(['rehana']), demand([dataset(12), supplement_class('given_name')])).
ml_word('relate', verb, forms(['relate', 'related', 'relates', 'relating']), demand([question_corpus(21)])).
ml_word('relationship', noun, forms(['relationship', 'relationships']), demand([question_corpus(28), dataset(4)])).
ml_word('relax', noun, forms(['relax', 'relaxes']), demand([dataset(12)])).
ml_word('relax', verb, forms(['relax', 'relaxed', 'relaxes', 'relaxing']), demand([dataset(12)])).
ml_word('relax', adjective, forms(['relax']), demand([dataset(12)])).
ml_word('release', noun, forms(['release', 'releases']), demand([dataset(11)])).
ml_word('release', verb, forms(['release', 'released', 'releases', 'releasing']), demand([dataset(11), supplement_class('corpus_verb')])).
ml_word('rely', verb, forms(['relied', 'relies', 'rely', 'relying']), demand([question_corpus(2), supplement_class('corpus_verb')])).
ml_word('remain', verb, forms(['remain', 'remained', 'remaining', 'remains']), demand([dataset(167)])).
ml_word('remainder', noun, forms(['remainder', 'remainders']), demand([dataset(29), questioning_paper_lexicon, supplement_class('math_term')])).
ml_word('remainder', adjective, forms(['remainder']), demand([dataset(29), questioning_paper_lexicon])).
ml_word('remember', verb, forms(['remember', 'remembered', 'remembering', 'remembers']), demand([question_corpus(1), dataset(2), supplement_class('corpus_verb')])).
ml_word('remind', verb, forms(['remind', 'reminded', 'reminding', 'reminds']), demand([question_corpus(3), supplement_class('corpus_verb')])).
ml_word('remove', noun, forms(['remove', 'removes']), demand([dataset(45)])).
ml_word('remove', verb, forms(['remove', 'removed', 'removes', 'removing']), demand([dataset(64), supplement_class('corpus_verb')])).
ml_word('rena', given_name, forms(['rena']), demand([dataset(9), supplement_class('given_name')])).
ml_word('renovate', verb, forms(['renovate', 'renovated', 'renovates', 'renovating']), demand([dataset(2), supplement_class('corpus_verb')])).
ml_word('rent', noun, forms(['rent', 'rents']), demand([dataset(34)])).
ml_word('rent', verb, forms(['rent', 'rented', 'renting', 'rents']), demand([question_corpus(1), dataset(54)])).
ml_word('rep', noun, forms(['rep', 'reps']), demand([dataset(10), supplement_class('common_noun')])).
ml_word('rep', adjective, forms(['rep']), demand([dataset(4)])).
ml_word('repaint', verb, forms(['repaint', 'repainted', 'repainting', 'repaints']), demand([dataset(2), supplement_class('corpus_verb')])).
ml_word('repair', noun, forms(['repair', 'repairs']), demand([dataset(60)])).
ml_word('repair', verb, forms(['repair', 'repaired', 'repairing', 'repairs']), demand([dataset(81)])).
ml_word('repay', verb, forms(['repaid', 'repay', 'repaying', 'repays']), demand([dataset(4), supplement_class('corpus_verb')])).
ml_word('repeat', verb, forms(['repeat', 'repeated', 'repeating', 'repeats']), demand([dataset(6), supplement_class('corpus_verb')])).
ml_word('replace', verb, forms(['replace', 'replaced', 'replaces', 'replacing']), demand([question_corpus(1), dataset(2), supplement_class('corpus_verb')])).
ml_word('report', noun, forms(['report', 'reports']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('report', verb, forms(['report', 'reported', 'reporting', 'reports']), demand([dataset(6), supplement_class('corpus_verb')])).
ml_word('represent', verb, forms(['represent', 'represented', 'representing', 'represents']), demand([question_corpus(89), dataset(27), supplement_class('corpus_verb')])).
ml_word('representation', noun, forms(['representation', 'representations']), demand([question_corpus(18), supplement_class('math_term')])).
ml_word('representative', noun, forms(['representative', 'representatives']), demand([dataset(4)])).
ml_word('reptile', noun, forms(['reptile', 'reptiles']), demand([question_corpus(2)])).
ml_word('request', verb, forms(['request', 'requested', 'requesting', 'requests']), demand([dataset(2), supplement_class('corpus_verb')])).
ml_word('require', verb, forms(['require', 'required', 'requires', 'requiring']), demand([question_corpus(2), dataset(59), supplement_class('corpus_verb')])).
ml_word('requirement', noun, forms(['requirement', 'requirements']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('reread', verb, forms(['reread', 'rereading', 'rereads']), demand([dataset(8), supplement_class('corpus_verb')])).
ml_word('researcher', noun, forms(['researcher', 'researchers']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('reseed', verb, forms(['reseed', 'reseeded', 'reseeding', 'reseeds']), demand([dataset(8), supplement_class('corpus_verb')])).
ml_word('resident', noun, forms(['resident', 'residents']), demand([dataset(11)])).
ml_word('residual', noun, forms(['residual', 'residuals']), demand([webster_domain('math')])).
ml_word('resolve', noun, forms(['resolve', 'resolves']), demand([question_corpus(1)])).
ml_word('respectfully', adverb, forms(['respectfully']), demand([question_corpus(1), supplement_class('adverb')])).
ml_word('respectively', adverb, forms(['respectively']), demand([dataset(13)])).
ml_word('respond', verb, forms(['respond', 'responded', 'responding', 'responds']), demand([dataset(8)])).
ml_word('response', noun, forms(['response', 'responses']), demand([question_corpus(6), supplement_class('math_term')])).
ml_word('rest', noun, forms(['rest', 'rests']), demand([question_corpus(1), dataset(126)])).
ml_word('rest', verb, forms(['rest', 'rested', 'resting', 'rests']), demand([question_corpus(1), dataset(126)])).
ml_word('restart', noun, forms(['restart', 'restarts']), demand([dataset(45), supplement_class('common_noun')])).
ml_word('restart', verb, forms(['restart', 'restarted', 'restarting', 'restarts']), demand([dataset(45), supplement_class('corpus_verb')])).
ml_word('restate', verb, forms(['restate', 'restated', 'restates', 'restating']), demand([question_corpus(99), supplement_class('corpus_verb')])).
ml_word('restaurant', noun, forms(['restaurant', 'restaurants']), demand([dataset(21), supplement_class('common_noun')])).
ml_word('restroom', noun, forms(['restroom', 'restrooms']), demand([dataset(10), supplement_class('common_noun')])).
ml_word('result', noun, forms(['result', 'results']), demand([question_corpus(9), dataset(4)])).
ml_word('result', verb, forms(['result', 'resulted', 'resulting', 'results']), demand([question_corpus(9), dataset(4)])).
ml_word('retailer', noun, forms(['retailer', 'retailers']), demand([dataset(2)])).
ml_word('retrieve', verb, forms(['retrieve', 'retrieved', 'retrieves', 'retrieving']), demand([dataset(2)])).
ml_word('return', noun, forms(['return', 'returns']), demand([dataset(27)])).
ml_word('return', verb, forms(['return', 'returned', 'returning', 'returns']), demand([question_corpus(1), dataset(42)])).
ml_word('reunion', noun, forms(['reunion', 'reunions']), demand([dataset(10)])).
ml_word('reusable', adjective, forms(['reusable']), demand([question_corpus(1), supplement_class('adjective')])).
ml_word('revenue', noun, forms(['revenue', 'revenues']), demand([dataset(32)])).
ml_word('reverse', noun, forms(['reverse', 'reverses']), demand([dataset(3)])).
ml_word('reverse', verb, forms(['reverse', 'reversed', 'reverses', 'reversing']), demand([dataset(3)])).
ml_word('reverse', adjective, forms(['reverse']), demand([dataset(3)])).
ml_word('revise', noun, forms(['revise', 'revises']), demand([question_corpus(7)])).
ml_word('revise', verb, forms(['revise', 'revised', 'revises', 'revising']), demand([question_corpus(7)])).
ml_word('revisit', verb, forms(['revisit', 'revisited', 'revisiting', 'revisits']), demand([question_corpus(1)])).
ml_word('reward', noun, forms(['reward', 'rewards']), demand([dataset(33)])).
ml_word('reward', verb, forms(['reward', 'rewarded', 'rewarding', 'rewards']), demand([dataset(33)])).
ml_word('rewind', verb, forms(['rewind', 'rewinding', 'rewinds', 'rewound']), demand([dataset(52), supplement_class('corpus_verb')])).
ml_word('rewrite', verb, forms(['rewrite', 'rewrites', 'rewriting', 'rewritten', 'rewrote']), demand([question_corpus(3)])).
ml_word('reynald', given_name, forms(['reynald']), demand([dataset(6), supplement_class('given_name')])).
ml_word('rho', algebra_symbol, forms(['rho']), demand([question_corpus(1), supplement_class('algebra_symbol')])).
ml_word('rhombus', noun, forms(['rhombus', 'rhombuses']), demand([question_corpus(3)])).
ml_word('ribbon', noun, forms(['ribbon', 'ribbons']), demand([question_corpus(1), dataset(8)])).
ml_word('ribbon', verb, forms(['ribbon', 'ribboned', 'ribboning', 'ribbons']), demand([question_corpus(1), dataset(8)])).
ml_word('rice', noun, forms(['rice', 'rices']), demand([question_corpus(2), dataset(83)])).
ml_word('richard', given_name, forms(['richard']), demand([dataset(4), supplement_class('given_name')])).
ml_word('rick', noun, forms(['rick', 'ricks']), demand([dataset(35)])).
ml_word('rick', verb, forms(['rick', 'ricked', 'ricking', 'ricks']), demand([dataset(35)])).
ml_word('riddle', noun, forms(['riddle', 'riddles']), demand([question_corpus(1)])).
ml_word('riddle', verb, forms(['riddle', 'riddled', 'riddles', 'riddling']), demand([question_corpus(1)])).
ml_word('ride', noun, forms(['ride', 'rides']), demand([question_corpus(2), dataset(98)])).
ml_word('ride', verb, forms(['ridden', 'ride', 'rides', 'riding', 'rode']), demand([question_corpus(2), dataset(111)])).
ml_word('riding', noun, forms(['riding', 'ridings']), demand([dataset(5)])).
ml_word('riding', adjective, forms(['riding']), demand([dataset(5)])).
ml_word('rig', noun, forms(['rig', 'rigs']), demand([question_corpus(2)])).
ml_word('rig', verb, forms(['rig', 'riged', 'rigged', 'rigging', 'riging', 'rigs']), demand([question_corpus(2)])).
ml_word('right', noun, forms(['right', 'rights']), demand([question_corpus(14), dataset(34)])).
ml_word('right', verb, forms(['right', 'righted', 'righting', 'rights']), demand([question_corpus(14), dataset(34)])).
ml_word('right', adjective, forms(['right']), demand([question_corpus(14), dataset(34)])).
ml_word('right', adverb, forms(['right']), demand([question_corpus(14), dataset(34)])).
ml_word('rigid', adjective, forms(['rigid']), demand([question_corpus(2)])).
ml_word('ring', noun, forms(['ring', 'rings']), demand([dataset(52)])).
ml_word('ring', verb, forms(['rang', 'ring', 'ringed', 'ringing', 'rings', 'rung']), demand([dataset(52)])).
ml_word('ris', noun, forms(['ris', 'rises']), demand([dataset(6)])).
ml_word('rise', noun, forms(['rise', 'rises']), demand([dataset(16)])).
ml_word('rise', verb, forms(['rise', 'risen', 'rises', 'rising', 'rose']), demand([dataset(39)])).
ml_word('river', noun, forms(['river', 'rivers']), demand([dataset(30)])).
ml_word('river', verb, forms(['river', 'rivered', 'rivering', 'rivers']), demand([dataset(30)])).
ml_word('riverbed', noun, forms(['riverbed', 'riverbeds']), demand([dataset(14), supplement_class('common_noun')])).
ml_word('road', noun, forms(['road', 'roads']), demand([dataset(36)])).
ml_word('roadway', noun, forms(['roadway', 'roadways']), demand([dataset(4)])).
ml_word('robi', given_name, forms(['robi']), demand([dataset(4), supplement_class('given_name')])).
ml_word('robot', noun, forms(['robot', 'robots']), demand([question_corpus(1), dataset(16), supplement_class('common_noun')])).
ml_word('robotics', noun, forms(['robotics']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('rock', noun, forms(['rock', 'rocks']), demand([dataset(33)])).
ml_word('rock', verb, forms(['rock', 'rocked', 'rocking', 'rocks']), demand([dataset(37)])).
ml_word('rocking', adjective, forms(['rocking']), demand([dataset(4)])).
ml_word('rode', noun, forms(['rode', 'rodes']), demand([dataset(8)])).
ml_word('roll', noun, forms(['roll', 'rolls']), demand([question_corpus(2), dataset(23)])).
ml_word('roll', verb, forms(['roll', 'rolled', 'rolling', 'rolls']), demand([question_corpus(3), dataset(23)])).
ml_word('roman', noun, forms(['roman', 'romans']), demand([dataset(6)])).
ml_word('roman', adjective, forms(['roman']), demand([dataset(6)])).
ml_word('ron', given_name, forms(['ron']), demand([dataset(11), supplement_class('given_name')])).
ml_word('roof', noun, forms(['roof', 'roofs']), demand([dataset(8)])).
ml_word('roof', verb, forms(['roof', 'roofed', 'roofing', 'rooves']), demand([dataset(8)])).
ml_word('room', noun, forms(['room', 'rooms']), demand([question_corpus(2), dataset(88)])).
ml_word('room', verb, forms(['room', 'roomed', 'rooming', 'rooms']), demand([question_corpus(2), dataset(88)])).
ml_word('room', adjective, forms(['room']), demand([question_corpus(1), dataset(78)])).
ml_word('roommate', noun, forms(['roommate', 'roommates']), demand([dataset(11)])).
ml_word('rooster', noun, forms(['rooster', 'roosters']), demand([dataset(2)])).
ml_word('root', noun, forms(['root', 'roots']), demand([question_corpus(1), dataset(1), questioning_paper_lexicon])).
ml_word('root', verb, forms(['root', 'rooted', 'rooting', 'roots']), demand([question_corpus(1), dataset(1), questioning_paper_lexicon])).
ml_word('rope', noun, forms(['rope', 'ropes']), demand([question_corpus(3), dataset(7)])).
ml_word('rope', verb, forms(['rope', 'roped', 'ropes', 'roping']), demand([question_corpus(3), dataset(7)])).
ml_word('rose', noun, forms(['rose', 'roses']), demand([dataset(41)])).
ml_word('rose', verb, forms(['rose', 'rosed', 'roses', 'rosing']), demand([dataset(41)])).
ml_word('rosie', given_name, forms(['rosie']), demand([dataset(14), supplement_class('given_name')])).
ml_word('rotation', noun, forms(['rotation', 'rotations']), demand([question_corpus(2), questioning_paper_lexicon])).
ml_word('rotation', adjective, forms(['rotation']), demand([question_corpus(1), questioning_paper_lexicon])).
ml_word('roughly', adverb, forms(['roughly']), demand([dataset(10)])).
ml_word('rouleau', noun, forms(['f', 'rouleau', 'rouleaus', 'rouleaux']), demand([dataset(12)])).
ml_word('round', noun, forms(['round', 'rounds']), demand([question_corpus(1), dataset(83)])).
ml_word('round', verb, forms(['round', 'rounded', 'rounding', 'rounds']), demand([question_corpus(4), dataset(114)])).
ml_word('round', adjective, forms(['round']), demand([question_corpus(1), dataset(71)])).
ml_word('round', adverb, forms(['round']), demand([question_corpus(1), dataset(71)])).
ml_word('round', preposition, forms(['round']), demand([question_corpus(1), dataset(71)])).
ml_word('rounded', adjective, forms(['rounded']), demand([dataset(29)])).
ml_word('rounding', noun, forms(['rounding', 'roundings']), demand([question_corpus(3), dataset(2)])).
ml_word('rounding', adjective, forms(['rounding']), demand([question_corpus(3), dataset(2)])).
ml_word('router', noun, forms(['router', 'routers']), demand([dataset(2)])).
ml_word('routine', noun, forms(['routine', 'routines']), demand([question_corpus(6)])).
ml_word('row', noun, forms(['row', 'rows']), demand([question_corpus(8), dataset(56)])).
ml_word('row', verb, forms(['row', 'rowed', 'rowing', 'rows']), demand([question_corpus(8), dataset(56)])).
ml_word('row', adjective, forms(['row']), demand([question_corpus(5), dataset(19)])).
ml_word('row', adverb, forms(['row']), demand([question_corpus(5), dataset(19)])).
ml_word('rubber', noun, forms(['rubber', 'rubbers']), demand([dataset(16)])).
ml_word('rule', noun, forms(['rule', 'rules']), demand([question_corpus(4)])).
ml_word('rule', verb, forms(['rule', 'ruled', 'rules', 'ruling']), demand([question_corpus(4)])).
ml_word('ruler', noun, forms(['ruler', 'rulers']), demand([question_corpus(5)])).
ml_word('rum', noun, forms(['rum', 'rums']), demand([dataset(17)])).
ml_word('rum', adjective, forms(['rum']), demand([dataset(17)])).
ml_word('run', noun, forms(['run', 'runs']), demand([question_corpus(1), dataset(179)])).
ml_word('run', verb, forms(['ran', 'run', 'running', 'runs']), demand([question_corpus(5), dataset(260)])).
ml_word('run', adjective, forms(['run']), demand([question_corpus(1), dataset(108)])).
ml_word('runner', noun, forms(['runner', 'runners']), demand([dataset(4)])).
ml_word('running', noun, forms(['running', 'runnings']), demand([question_corpus(2), dataset(45)])).
ml_word('running', adjective, forms(['running']), demand([question_corpus(2), dataset(45)])).
ml_word('runoff', noun, forms(['runoff', 'runoffs']), demand([question_corpus(3), supplement_class('common_noun')])).
ml_word('runway', noun, forms(['runway', 'runways']), demand([dataset(30)])).
ml_word('rush', noun, forms(['rush', 'rushes']), demand([dataset(8)])).
ml_word('rush', verb, forms(['rush', 'rushed', 'rushes', 'rushing']), demand([dataset(8)])).
ml_word('russia', noun, forms(['russia', 'russias']), demand([dataset(8)])).
ml_word('ruth', noun, forms(['ruth', 'ruths']), demand([dataset(4)])).
ml_word('ryan', given_name, forms(['ryan']), demand([dataset(20), supplement_class('given_name')])).
ml_word('sack', noun, forms(['sack', 'sacks']), demand([dataset(45)])).
ml_word('sack', verb, forms(['sack', 'sacked', 'sacking', 'sacks']), demand([dataset(45)])).
ml_word('safe', noun, forms(['safe', 'saves']), demand([dataset(21)])).
ml_word('safe', verb, forms(['safe', 'safed', 'safes', 'safing']), demand([dataset(5)])).
ml_word('safe', adjective, forms(['safe']), demand([dataset(5)])).
ml_word('safety', noun, forms(['safeties', 'safety']), demand([dataset(3)])).
ml_word('said', adjective, forms(['said']), demand([dataset(33)])).
ml_word('sail', verb, forms(['sail', 'sailed', 'sailing', 'sails']), demand([dataset(4)])).
ml_word('salad', noun, forms(['salad', 'salads']), demand([dataset(12)])).
ml_word('salary', noun, forms(['salaries', 'salary']), demand([dataset(17)])).
ml_word('salary', adjective, forms(['salary']), demand([dataset(17)])).
ml_word('sale', noun, forms(['sale', 'sales']), demand([question_corpus(1), dataset(116)])).
ml_word('saleswoman', noun, forms(['saleswoman', 'saleswomen']), demand([dataset(12)])).
ml_word('salisbury', place_name, forms(['salisbury']), demand([dataset(7), supplement_class('place_name')])).
ml_word('sally', noun, forms(['sallies', 'sally']), demand([dataset(49)])).
ml_word('sally', verb, forms(['sallied', 'sallies', 'sally', 'sallying']), demand([dataset(49)])).
ml_word('salmon', noun, forms(['salmon', 'salmons']), demand([dataset(14)])).
ml_word('salmon', adjective, forms(['salmon']), demand([dataset(14)])).
ml_word('salsa', noun, forms(['salsa', 'salsas']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('sam', adverb, forms(['sam']), demand([dataset(75)])).
ml_word('samantha', given_name, forms(['samantha']), demand([dataset(4), supplement_class('given_name')])).
ml_word('same', adjective, forms(['same']), demand([question_corpus(166), dataset(235)])).
ml_word('sammy', given_name, forms(['sammy']), demand([dataset(22), supplement_class('given_name')])).
ml_word('sample', noun, forms(['sample', 'samples']), demand([question_corpus(5), dataset(24)])).
ml_word('sample', verb, forms(['sample', 'sampled', 'samples', 'sampling']), demand([question_corpus(6), dataset(24)])).
ml_word('samuel', given_name, forms(['samuel']), demand([dataset(9), supplement_class('given_name')])).
ml_word('san', place_name, forms(['san']), demand([question_corpus(1), supplement_class('place_name')])).
ml_word('sand', noun, forms(['sand', 'sands']), demand([dataset(33)])).
ml_word('sand', verb, forms(['sand', 'sanded', 'sanding', 'sands']), demand([dataset(33)])).
ml_word('sandbag', noun, forms(['sandbag', 'sandbags']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('sandoval', family_name, forms(['sandoval']), demand([dataset(18), supplement_class('family_name')])).
ml_word('sandra', given_name, forms(['sandra']), demand([dataset(16), supplement_class('given_name')])).
ml_word('sandwich', noun, forms(['sandwich', 'sandwiches']), demand([question_corpus(1), dataset(112)])).
ml_word('sandwich', verb, forms(['sandwich', 'sandwiched', 'sandwiches', 'sandwiching']), demand([question_corpus(1), dataset(112)])).
ml_word('sandy', adjective, forms(['sandier', 'sandiest', 'sandy']), demand([dataset(38)])).
ml_word('sangita', given_name, forms(['sangita']), demand([dataset(7), supplement_class('given_name')])).
ml_word('sarah', given_name, forms(['sarah']), demand([dataset(34), supplement_class('given_name')])).
ml_word('sarith', given_name, forms(['sarith']), demand([dataset(20), supplement_class('given_name')])).
ml_word('satisfy', verb, forms(['satisfied', 'satisfies', 'satisfy', 'satisfying']), demand([dataset(2)])).
ml_word('saturday', noun, forms(['saturday', 'saturdays']), demand([dataset(35), supplement_class('temporal_word')])).
ml_word('saturn', noun, forms(['saturn', 'saturns']), demand([question_corpus(1)])).
ml_word('sauce', noun, forms(['sauce', 'sauces']), demand([dataset(7)])).
ml_word('sauce', verb, forms(['sauce', 'sauced', 'sauces', 'saucing']), demand([dataset(7)])).
ml_word('sausage', noun, forms(['sausage', 'sausages']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('save', noun, forms(['save', 'saves']), demand([dataset(63)])).
ml_word('save', verb, forms(['save', 'saved', 'saves', 'saving']), demand([dataset(83)])).
ml_word('save', preposition, forms(['save']), demand([dataset(47)])).
ml_word('save', conjunction, forms(['save']), demand([dataset(47)])).
ml_word('saving', noun, forms(['saving', 'savings']), demand([dataset(25)])).
ml_word('saving', adjective, forms(['saving']), demand([dataset(6)])).
ml_word('saving', preposition, forms(['saving']), demand([dataset(6)])).
ml_word('savory', noun, forms(['savories', 'savory']), demand([question_corpus(1)])).
ml_word('savory', adjective, forms(['savory']), demand([question_corpus(1)])).
ml_word('saw', noun, forms(['saw', 'saws']), demand([question_corpus(6), dataset(35)])).
ml_word('saw', verb, forms(['saw', 'sawed', 'sawing', 'saws']), demand([question_corpus(6), dataset(35)])).
ml_word('say', noun, forms(['say', 'says']), demand([question_corpus(53), dataset(45)])).
ml_word('say', verb, forms(['said', 'say', 'saying', 'says']), demand([question_corpus(53), dataset(84)])).
ml_word('saying', noun, forms(['saying', 'sayings']), demand([dataset(6)])).
ml_word('scalar', noun, forms(['scalar', 'scalars']), demand([webster_domain('math')])).
ml_word('scald', verb, forms(['scald', 'scalding', 'scalds', 'scaled']), demand([question_corpus(3)])).
ml_word('scale', noun, forms(['scale', 'scales']), demand([question_corpus(12), dataset(4), questioning_paper_lexicon])).
ml_word('scale', verb, forms(['scale', 'scaled', 'scales', 'scaling']), demand([question_corpus(15), dataset(4), questioning_paper_lexicon])).
ml_word('scaled', adjective, forms(['scaled']), demand([question_corpus(3)])).
ml_word('scalene', noun, forms(['scalene', 'scalenes']), demand([webster_domain('geom')])).
ml_word('scalene', adjective, forms(['scalene']), demand([webster_domain('geom')])).
ml_word('scallop', noun, forms(['scallop', 'scallops']), demand([dataset(22)])).
ml_word('scallop', verb, forms(['scallop', 'scalloped', 'scalloping', 'scallops']), demand([dataset(22)])).
ml_word('scar', verb, forms(['scar', 'scared', 'scaring', 'scarred', 'scarring', 'scars']), demand([dataset(2)])).
ml_word('scare', verb, forms(['scare', 'scared', 'scares', 'scaring']), demand([dataset(2)])).
ml_word('scarf', noun, forms(['scarf', 'scarfs', 'scarves']), demand([dataset(19)])).
ml_word('scarf', verb, forms(['scarf', 'scarfed', 'scarfing', 'scarves']), demand([dataset(19)])).
ml_word('scatter', verb, forms(['scatter', 'scattered', 'scattering', 'scatters']), demand([question_corpus(3), dataset(2), questioning_paper_lexicon])).
ml_word('scattered', adjective, forms(['scattered']), demand([dataset(2)])).
ml_word('scent', noun, forms(['scent', 'scents']), demand([dataset(36)])).
ml_word('scent', verb, forms(['scent', 'scented', 'scenting', 'scents']), demand([dataset(40)])).
ml_word('schedule', verb, forms(['schedule', 'scheduled', 'schedules', 'scheduling']), demand([dataset(4)])).
ml_word('school', noun, forms(['school', 'schools']), demand([question_corpus(12), dataset(188)])).
ml_word('school', verb, forms(['school', 'schooled', 'schooling', 'schools']), demand([question_corpus(12), dataset(188)])).
ml_word('science', noun, forms(['science', 'sciences']), demand([dataset(6)])).
ml_word('science', verb, forms(['science', 'scienced', 'sciences', 'sciencing']), demand([dataset(6)])).
ml_word('scientific', adjective, forms(['scientific']), demand([question_corpus(1)])).
ml_word('scientist', noun, forms(['scientist', 'scientists']), demand([dataset(4)])).
ml_word('scoop', noun, forms(['scoop', 'scoops']), demand([dataset(78)])).
ml_word('scoop', verb, forms(['scoop', 'scooped', 'scooping', 'scoops']), demand([dataset(86)])).
ml_word('score', noun, forms(['score', 'scores']), demand([question_corpus(1), dataset(132)])).
ml_word('score', verb, forms(['score', 'scored', 'scores', 'scoring']), demand([question_corpus(1), dataset(214)])).
ml_word('scorn', verb, forms(['scoring', 'scorn', 'scorned', 'scorning', 'scorns']), demand([dataset(2)])).
ml_word('scout', noun, forms(['scout', 'scouts']), demand([dataset(2)])).
ml_word('scout', verb, forms(['scout', 'scouted', 'scouting', 'scouts']), demand([dataset(2)])).
ml_word('script', noun, forms(['script', 'scripts']), demand([dataset(4)])).
ml_word('sea', noun, forms(['sea', 'seas']), demand([question_corpus(1)])).
ml_word('seabed', noun, forms(['seabed', 'seabeds']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('seahawks', named_entity, forms(['seahawks']), demand([dataset(24), supplement_class('named_entity')])).
ml_word('search', noun, forms(['search', 'searches']), demand([question_corpus(1), dataset(4)])).
ml_word('search', verb, forms(['search', 'searched', 'searches', 'searching']), demand([question_corpus(1), dataset(4)])).
ml_word('seashell', noun, forms(['seashell', 'seashells']), demand([dataset(35)])).
ml_word('seashore', noun, forms(['seashore', 'seashores']), demand([dataset(8)])).
ml_word('season', noun, forms(['season', 'seasons']), demand([question_corpus(1), dataset(37)])).
ml_word('season', verb, forms(['season', 'seasoned', 'seasoning', 'seasons']), demand([question_corpus(1), dataset(37)])).
ml_word('seat', noun, forms(['seat', 'seats']), demand([question_corpus(1), dataset(13)])).
ml_word('seat', verb, forms(['seat', 'seated', 'seating', 'seats']), demand([question_corpus(1), dataset(15)])).
ml_word('seating', noun, forms(['seating', 'seatings']), demand([dataset(2)])).
ml_word('seattle', place_name, forms(['seattle']), demand([dataset(24), supplement_class('place_name')])).
ml_word('sec', unit_abbreviation, forms(['sec']), demand([dataset(5), supplement_class('unit_abbreviation')])).
ml_word('second', noun, forms(['second', 'seconds']), demand([question_corpus(33), dataset(480)])).
ml_word('second', verb, forms(['second', 'seconded', 'seconding', 'seconds']), demand([question_corpus(33), dataset(480)])).
ml_word('second', adjective, forms(['second']), demand([question_corpus(32), dataset(328)])).
ml_word('secretly', adverb, forms(['secretly']), demand([dataset(3)])).
ml_word('section', noun, forms(['section', 'sections']), demand([question_corpus(3), dataset(33)])).
ml_word('see', noun, forms(['see', 'sees']), demand([question_corpus(181), dataset(37)])).
ml_word('see', verb, forms(['saw', 'see', 'seeing', 'seen', 'sees']), demand([question_corpus(202), dataset(74)])).
ml_word('seed', noun, forms(['seed', 'seeds']), demand([question_corpus(1), dataset(73)])).
ml_word('seed', verb, forms(['seed', 'seeded', 'seeding', 'seeds']), demand([question_corpus(1), dataset(73)])).
ml_word('seeing', conjunction, forms(['seeing']), demand([question_corpus(3), dataset(2)])).
ml_word('seem', verb, forms(['seem', 'seemed', 'seeming', 'seems']), demand([question_corpus(3)])).
ml_word('seen', adjective, forms(['seen']), demand([question_corpus(12)])).
ml_word('segment', noun, forms(['segment', 'segments']), demand([question_corpus(2), dataset(28)])).
ml_word('segment', verb, forms(['segment', 'segmented', 'segmenting', 'segments']), demand([question_corpus(2), dataset(28)])).
ml_word('select', verb, forms(['select', 'selected', 'selecting', 'selects']), demand([question_corpus(6), dataset(2)])).
ml_word('select', adjective, forms(['select']), demand([question_corpus(2)])).
ml_word('sell', noun, forms(['sell', 'sells']), demand([question_corpus(1), dataset(271)])).
ml_word('sell', verb, forms(['sell', 'selling', 'sells', 'sold']), demand([question_corpus(2), dataset(736)])).
ml_word('semester', noun, forms(['semester', 'semesters']), demand([dataset(26)])).
ml_word('semi', adjective, forms(['semi']), demand([dataset(6), supplement_class('adjective')])).
ml_word('semiangle', noun, forms(['semiangle', 'semiangles']), demand([webster_domain('geom')])).
ml_word('semiaxis', noun, forms(['semiaxis', 'semiaxises']), demand([webster_domain('geom')])).
ml_word('semidiameter', noun, forms(['semidiameter', 'semidiameters']), demand([webster_domain('math')])).
ml_word('semilune', noun, forms(['semilune', 'semilunes']), demand([webster_domain('geom')])).
ml_word('semiparabola', noun, forms(['semiparabola', 'semiparabolas']), demand([webster_domain('geom')])).
ml_word('semitangent', noun, forms(['semitangent', 'semitangents']), demand([webster_domain('geom')])).
ml_word('send', noun, forms(['send', 'sends']), demand([dataset(9)])).
ml_word('send', verb, forms(['send', 'sended', 'sending', 'sends', 'sent']), demand([dataset(35)])).
ml_word('senior', noun, forms(['senior', 'seniors']), demand([dataset(7)])).
ml_word('senior', adjective, forms(['senior']), demand([dataset(7)])).
ml_word('sense', noun, forms(['sense', 'senses']), demand([question_corpus(15)])).
ml_word('sense', verb, forms(['sense', 'sensed', 'senses', 'sensing']), demand([question_corpus(15)])).
ml_word('sent', noun, forms(['sent', 'sents']), demand([dataset(24)])).
ml_word('sent', verb, forms(['sent']), demand([dataset(24)])).
ml_word('sentence', noun, forms(['sentence', 'sentences']), demand([dataset(2)])).
ml_word('sentence', verb, forms(['sentence', 'sentenced', 'sentences', 'sentencing']), demand([dataset(2)])).
ml_word('separate', verb, forms(['separate', 'separated', 'separates', 'separating']), demand([question_corpus(1), dataset(20)])).
ml_word('separate', adjective, forms(['separate']), demand([question_corpus(1), dataset(20)])).
ml_word('september', noun, forms(['september', 'septembers']), demand([dataset(22)])).
ml_word('serie', noun, forms(['serie', 'series']), demand([question_corpus(2), dataset(4)])).
ml_word('series', noun, forms(['series', 'serieses']), demand([question_corpus(2), dataset(4)])).
ml_word('seriph', noun, forms(['seriph', 'type']), demand([question_corpus(1), dataset(20)])).
ml_word('serve', verb, forms(['serve', 'served', 'serves', 'serving']), demand([question_corpus(1), dataset(69)])).
ml_word('service', noun, forms(['service', 'services']), demand([dataset(8)])).
ml_word('serving', noun, forms(['serving', 'servings']), demand([dataset(11), supplement_class('common_noun')])).
ml_word('session', noun, forms(['session', 'sessions']), demand([dataset(10)])).
ml_word('set', noun, forms(['set', 'sets']), demand([question_corpus(12), dataset(178)])).
ml_word('set', verb, forms(['set', 'sets', 'setting']), demand([question_corpus(13), dataset(185)])).
ml_word('set', adjective, forms(['set']), demand([question_corpus(8), dataset(77)])).
ml_word('setting', noun, forms(['setting', 'settings']), demand([question_corpus(1), dataset(7)])).
ml_word('seven', noun, forms(['seven', 'sevens']), demand([dataset(13)])).
ml_word('seven', adjective, forms(['seven']), demand([dataset(13)])).
ml_word('seventeen', noun, forms(['seventeen', 'seventeens']), demand([dataset(4)])).
ml_word('seventeen', adjective, forms(['seventeen']), demand([dataset(4)])).
ml_word('seventh', noun, forms(['seventh', 'sevenths']), demand([dataset(2)])).
ml_word('seventh', adjective, forms(['seventh']), demand([dataset(2)])).
ml_word('several', noun, forms(['several', 'severals']), demand([dataset(10)])).
ml_word('several', adjective, forms(['several']), demand([dataset(10)])).
ml_word('several', adverb, forms(['several']), demand([dataset(10)])).
ml_word('sew', noun, forms(['sew', 'sews']), demand([dataset(10)])).
ml_word('sew', verb, forms(['sew', 'sewed', 'sewing', 'sews']), demand([dataset(12)])).
ml_word('sewe', verb, forms(['sewe', 'sewed', 'sewes', 'sewing']), demand([dataset(2)])).
ml_word('sewer', noun, forms(['sewer', 'sewers']), demand([dataset(3)])).
ml_word('sewing', noun, forms(['sewing', 'sewings']), demand([dataset(2)])).
ml_word('shade', noun, forms(['shade', 'shades']), demand([question_corpus(2), dataset(4)])).
ml_word('shade', verb, forms(['shade', 'shaded', 'shades', 'shading']), demand([question_corpus(14), dataset(4)])).
ml_word('shady', adjective, forms(['shadier', 'shadiest', 'shady']), demand([dataset(3)])).
ml_word('shannen', given_name, forms(['shannen']), demand([dataset(16), supplement_class('given_name')])).
ml_word('shape', noun, forms(['shape', 'shapes']), demand([question_corpus(59), dataset(4)])).
ml_word('shape', verb, forms(['shape', 'shaped', 'shapes', 'shaping']), demand([question_corpus(59), dataset(15)])).
ml_word('share', noun, forms(['share', 'shares']), demand([question_corpus(5), dataset(25)])).
ml_word('share', verb, forms(['share', 'shared', 'shares', 'sharing']), demand([question_corpus(10), dataset(46)])).
ml_word('sharpen', verb, forms(['sarpened', 'sharpen', 'sharpened', 'sharpening', 'sharpens']), demand([dataset(14)])).
ml_word('sharpener', noun, forms(['sharpener', 'sharpeners']), demand([dataset(15), supplement_class('common_noun')])).
ml_word('shawn', given_name, forms(['shawn']), demand([dataset(4), supplement_class('given_name')])).
ml_word('shawna', given_name, forms(['shawna']), demand([dataset(33), supplement_class('given_name')])).
ml_word('she', pronoun, forms(['she']), demand([question_corpus(6), dataset(2490)])).
ml_word('sheena', given_name, forms(['sheena']), demand([dataset(6), supplement_class('given_name')])).
ml_word('sheet', noun, forms(['sheet', 'sheets']), demand([question_corpus(1), dataset(10)])).
ml_word('sheet', verb, forms(['sheet', 'sheeted', 'sheeting', 'sheets']), demand([question_corpus(1), dataset(10)])).
ml_word('sheila', given_name, forms(['sheila']), demand([dataset(10), supplement_class('given_name')])).
ml_word('shelby', given_name, forms(['shelby']), demand([dataset(9), supplement_class('given_name')])).
ml_word('shelf', noun, forms(['shelf', 'shelves']), demand([dataset(4)])).
ml_word('shell', noun, forms(['shell', 'shells']), demand([dataset(6)])).
ml_word('shell', verb, forms(['shell', 'shelled', 'shelling', 'shells']), demand([dataset(6)])).
ml_word('shelve', verb, forms(['shelve', 'shelved', 'shelves', 'shelving']), demand([dataset(30)])).
ml_word('shelving', noun, forms(['shelving', 'shelvings']), demand([dataset(30)])).
ml_word('shelving', adjective, forms(['shelving']), demand([dataset(30)])).
ml_word('shepherd', noun, forms(['shepherd', 'shepherds']), demand([dataset(9)])).
ml_word('shepherd', verb, forms(['shepherd', 'shepherded', 'shepherding', 'shepherds']), demand([dataset(9)])).
ml_word('shift', noun, forms(['shift', 'shifts']), demand([dataset(12)])).
ml_word('shift', verb, forms(['shift', 'shifted', 'shifting', 'shifts']), demand([dataset(12)])).
ml_word('ship', noun, forms(['ship', 'ships']), demand([dataset(4)])).
ml_word('ship', verb, forms(['ship', 'shiped', 'shiping', 'shipped', 'shipping', 'ships']), demand([question_corpus(2), dataset(16)])).
ml_word('shipping', noun, forms(['shipping', 'shippings']), demand([question_corpus(2), dataset(10)])).
ml_word('shipping', adjective, forms(['shipping']), demand([question_corpus(2), dataset(10)])).
ml_word('shirt', noun, forms(['shirt', 'shirts']), demand([question_corpus(1), dataset(69)])).
ml_word('shirt', verb, forms(['shirt', 'shirted', 'shirting', 'shirts']), demand([question_corpus(1), dataset(69)])).
ml_word('shoe', noun, forms(['shoe', 'shoes', 'shoon']), demand([dataset(82)])).
ml_word('shoe', verb, forms(['shod', 'shoe', 'shoeing', 'shoes']), demand([dataset(82)])).
ml_word('shoebox', noun, forms(['shoebox', 'shoeboxes']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('shoot', noun, forms(['shoot', 'shoots']), demand([dataset(9)])).
ml_word('shoot', verb, forms(['shoot', 'shooted', 'shooting', 'shoots', 'shot']), demand([dataset(12)])).
ml_word('shop', noun, forms(['shop', 'shops']), demand([dataset(60)])).
ml_word('shop', verb, forms(['shop', 'shopped', 'shopping', 'shops']), demand([dataset(112)])).
ml_word('shoplifter', noun, forms(['shoplifter', 'shoplifters']), demand([dataset(18)])).
ml_word('shoplifting', noun, forms(['shoplifting', 'shopliftings']), demand([dataset(6)])).
ml_word('short', noun, forms(['short', 'shorts']), demand([dataset(58)])).
ml_word('short', verb, forms(['short', 'shorted', 'shorting', 'shorts']), demand([dataset(58)])).
ml_word('short', adjective, forms(['short', 'shorter', 'shortest']), demand([question_corpus(3), dataset(68)])).
ml_word('short', adverb, forms(['short']), demand([dataset(58)])).
ml_word('shortage', noun, forms(['shortage', 'shortages']), demand([dataset(4)])).
ml_word('shorten', verb, forms(['shorten', 'shortened', 'shortening', 'shortens']), demand([dataset(3)])).
ml_word('shortening', noun, forms(['shortening', 'shortenings']), demand([dataset(3)])).
ml_word('shot', noun, forms(['shot', 'shotor', 'shots']), demand([dataset(3)])).
ml_word('shot', verb, forms(['shot', 'shots', 'shotted', 'shotting']), demand([dataset(3)])).
ml_word('shot', adjective, forms(['shot']), demand([dataset(3)])).
ml_word('show', noun, forms(['show', 'shows']), demand([question_corpus(56), dataset(95)])).
ml_word('show', verb, forms(['show', 'showed', 'showing', 'shown', 'shows']), demand([question_corpus(65), dataset(107)])).
ml_word('shower', noun, forms(['shower', 'showers']), demand([dataset(11)])).
ml_word('shower', verb, forms(['shower', 'showered', 'showering', 'showers']), demand([dataset(11)])).
ml_word('showing', noun, forms(['showing', 'showings']), demand([question_corpus(1)])).
ml_word('shred', verb, forms(['shred', 'shredded', 'shredding', 'shreds']), demand([dataset(4), supplement_class('corpus_verb')])).
ml_word('shrink', noun, forms(['shrink', 'shrinks']), demand([dataset(8)])).
ml_word('shrink', verb, forms(['shrank', 'shrink', 'shrinked', 'shrinking', 'shrinks', 'shrunk']), demand([dataset(12), supplement_class('corpus_verb')])).
ml_word('sibling', noun, forms(['sibling', 'siblings']), demand([dataset(13), supplement_class('common_noun')])).
ml_word('sick', noun, forms(['sick', 'sicks']), demand([dataset(14)])).
ml_word('sick', verb, forms(['sick', 'sicked', 'sicking', 'sicks']), demand([dataset(14)])).
ml_word('sick', adjective, forms(['sick', 'sicker', 'sickest']), demand([dataset(14)])).
ml_word('side', noun, forms(['side', 'sides']), demand([question_corpus(47), dataset(164)])).
ml_word('side', verb, forms(['side', 'sided', 'sides', 'siding']), demand([question_corpus(47), dataset(164)])).
ml_word('side', adjective, forms(['side']), demand([question_corpus(25), dataset(67)])).
ml_word('sidewalk', noun, forms(['sidewalk', 'sidewalks']), demand([dataset(7)])).
ml_word('sierra', noun, forms(['sierra', 'sierras']), demand([dataset(4)])).
ml_word('sigh', noun, forms(['sigh', 'sighs']), demand([dataset(10)])).
ml_word('sigh', verb, forms(['sigh', 'sighed', 'sighing', 'sighs']), demand([dataset(10)])).
ml_word('sign', noun, forms(['sign', 'signs']), demand([question_corpus(7), dataset(14)])).
ml_word('sign', verb, forms(['sign', 'signed', 'signing', 'signs']), demand([question_corpus(7), dataset(16)])).
ml_word('signature', noun, forms(['signature', 'signatures']), demand([dataset(4)])).
ml_word('signature', verb, forms(['signature', 'signatured', 'signatures', 'signaturing']), demand([dataset(4)])).
ml_word('silas', given_name, forms(['silas']), demand([dataset(5), supplement_class('given_name')])).
ml_word('similar', noun, forms(['similar', 'similars']), demand([question_corpus(8), dataset(4), questioning_paper_lexicon])).
ml_word('similar', adjective, forms(['similar']), demand([question_corpus(8), dataset(4), questioning_paper_lexicon])).
ml_word('similarly', adverb, forms(['similarly']), demand([dataset(6)])).
ml_word('simplify', verb, forms(['simplified', 'simplifies', 'simplify', 'simplifying']), demand([question_corpus(1), dataset(56)])).
ml_word('simply', adverb, forms(['simply']), demand([dataset(3)])).
ml_word('since', adverb, forms(['since']), demand([dataset(411)])).
ml_word('since', preposition, forms(['since']), demand([dataset(411)])).
ml_word('since', conjunction, forms(['since']), demand([dataset(411)])).
ml_word('sing', verb, forms(['sang', 'sing', 'singed', 'singing', 'sings', 'sung']), demand([question_corpus(1), dataset(47), supplement_class('corpus_verb')])).
ml_word('singer', noun, forms(['singer', 'singers']), demand([dataset(19)])).
ml_word('singing', noun, forms(['singing', 'singings']), demand([question_corpus(1), dataset(7)])).
ml_word('singing', adjective, forms(['singing']), demand([question_corpus(1), dataset(7)])).
ml_word('single', noun, forms(['single', 'singles']), demand([question_corpus(3), dataset(83)])).
ml_word('single', verb, forms(['single', 'singled', 'singles', 'singling']), demand([question_corpus(3), dataset(83)])).
ml_word('single', adjective, forms(['single']), demand([question_corpus(2), dataset(82)])).
ml_word('singles', noun, forms(['singles']), demand([question_corpus(1), dataset(1)])).
ml_word('sister', noun, forms(['sister', 'sisters']), demand([dataset(49)])).
ml_word('sister', verb, forms(['sister', 'sistered', 'sistering', 'sisters']), demand([dataset(49)])).
ml_word('site', noun, forms(['site', 'sites']), demand([dataset(16)])).
ml_word('situation', noun, forms(['situation', 'situations']), demand([question_corpus(41)])).
ml_word('situp', noun, forms(['situp', 'situps']), demand([dataset(48), supplement_class('common_noun')])).
ml_word('six', noun, forms(['six', 'sixes']), demand([question_corpus(1), dataset(82)])).
ml_word('six', adjective, forms(['six']), demand([question_corpus(1), dataset(82)])).
ml_word('sixth', noun, forms(['sixth', 'sixths']), demand([question_corpus(1), dataset(32)])).
ml_word('sixth', adjective, forms(['sixth']), demand([dataset(29)])).
ml_word('size', noun, forms(['size', 'sizes']), demand([question_corpus(13), dataset(71)])).
ml_word('size', verb, forms(['size', 'sized', 'sizes', 'sizing']), demand([question_corpus(13), dataset(73)])).
ml_word('sized', adjective, forms(['sized']), demand([dataset(2)])).
ml_word('sketch', noun, forms(['sketch', 'sketches']), demand([question_corpus(2)])).
ml_word('sketch', verb, forms(['sketch', 'sketched', 'sketches', 'sketching']), demand([question_corpus(2)])).
ml_word('ski', noun, forms(['ski', 'skis']), demand([dataset(10)])).
ml_word('ski', verb, forms(['ski', 'skied', 'skiing', 'skis']), demand([dataset(11), supplement_class('corpus_verb')])).
ml_word('skier', noun, forms(['skier', 'skiers']), demand([dataset(5), supplement_class('common_noun')])).
ml_word('skill', noun, forms(['skill', 'skills']), demand([dataset(2)])).
ml_word('skill', verb, forms(['skill', 'skilled', 'skilling', 'skills']), demand([dataset(2)])).
ml_word('skip', noun, forms(['skip', 'skips']), demand([dataset(3)])).
ml_word('skip', verb, forms(['skip', 'skiped', 'skiping', 'skipped', 'skipping', 'skips']), demand([dataset(3)])).
ml_word('skit', noun, forms(['skit', 'skits']), demand([dataset(4)])).
ml_word('skit', verb, forms(['skit', 'skited', 'skiting', 'skits']), demand([dataset(4)])).
ml_word('skull', noun, forms(['skull', 'skulls']), demand([dataset(3)])).
ml_word('slay', verb, forms(['slain', 'slay', 'slayed', 'slaying', 'slays', 'slew']), demand([dataset(2)])).
ml_word('sle', verb, forms(['sle', 'sled', 'sles', 'sling']), demand([dataset(5)])).
ml_word('sled', noun, forms(['sled', 'sleds']), demand([dataset(18)])).
ml_word('sled', verb, forms(['sled', 'sledded', 'sledding', 'sleds']), demand([dataset(20)])).
ml_word('sledding', noun, forms(['sledding', 'sleddings']), demand([dataset(2)])).
ml_word('sleep', noun, forms(['sleep', 'sleeps']), demand([dataset(6)])).
ml_word('sleep', verb, forms(['sleep', 'sleeping', 'sleeps', 'slept']), demand([dataset(8)])).
ml_word('sleeping', noun, forms(['sleeping', 'sleepings']), demand([dataset(2)])).
ml_word('sleeping', adjective, forms(['sleeping']), demand([dataset(2)])).
ml_word('sleepy', adjective, forms(['sleepier', 'sleepiest', 'sleepy']), demand([dataset(12)])).
ml_word('slice', noun, forms(['slice', 'slices']), demand([dataset(104)])).
ml_word('slice', verb, forms(['slice', 'sliced', 'slices', 'slicing']), demand([dataset(104)])).
ml_word('slide', noun, forms(['slide', 'slides']), demand([question_corpus(2)])).
ml_word('slide', verb, forms(['slid', 'slidden', 'slidding', 'slide', 'slided', 'slides', 'sliding']), demand([question_corpus(4)])).
ml_word('sliding', adjective, forms(['sliding']), demand([question_corpus(2)])).
ml_word('slip', noun, forms(['slip', 'slips']), demand([dataset(10)])).
ml_word('slip', verb, forms(['slip', 'sliped', 'sliping', 'slipped', 'slipping', 'slips']), demand([dataset(10)])).
ml_word('sloan', given_name, forms(['sloan']), demand([dataset(8), supplement_class('given_name')])).
ml_word('slope', noun, forms(['slope', 'slopes']), demand([question_corpus(8), questioning_paper_lexicon])).
ml_word('slope', verb, forms(['slope', 'sloped', 'slopes', 'sloping']), demand([question_corpus(8), questioning_paper_lexicon])).
ml_word('slope', adjective, forms(['slope']), demand([question_corpus(8), questioning_paper_lexicon])).
ml_word('slope', adverb, forms(['slope']), demand([question_corpus(8), questioning_paper_lexicon])).
ml_word('slot', noun, forms(['slot', 'slots']), demand([dataset(5)])).
ml_word('slot', verb, forms(['slot', 'sloted', 'sloting', 'slots']), demand([dataset(5)])).
ml_word('slow', adjective, forms(['slow', 'slower', 'slowest']), demand([question_corpus(1)])).
ml_word('slowly', adverb, forms(['slowly']), demand([dataset(14)])).
ml_word('small', noun, forms(['small', 'smalls']), demand([question_corpus(1), dataset(129)])).
ml_word('small', verb, forms(['small', 'smalled', 'smalling', 'smalls']), demand([question_corpus(1), dataset(129)])).
ml_word('small', adjective, forms(['small', 'smaller', 'smallest']), demand([question_corpus(5), dataset(146)])).
ml_word('small', adverb, forms(['small']), demand([question_corpus(1), dataset(129)])).
ml_word('smash', verb, forms(['smash', 'smashed', 'smashes', 'smashing']), demand([question_corpus(1)])).
ml_word('smell', noun, forms(['smell', 'smells']), demand([dataset(40)])).
ml_word('smell', verb, forms(['smell', 'smelled', 'smelling', 'smells']), demand([dataset(45)])).
ml_word('smelling', noun, forms(['smelling', 'smellings']), demand([dataset(5)])).
ml_word('smith', noun, forms(['smith', 'smiths']), demand([dataset(10)])).
ml_word('smith', verb, forms(['smith', 'smithed', 'smithing', 'smiths']), demand([dataset(10)])).
ml_word('smooth', noun, forms(['smooth', 'smooths']), demand([dataset(4)])).
ml_word('smooth', verb, forms(['smooth', 'smoothed', 'smoothing', 'smooths']), demand([dataset(4)])).
ml_word('smooth', adjective, forms(['smooth', 'smoother', 'smoothest']), demand([dataset(4)])).
ml_word('smooth', adverb, forms(['smooth']), demand([dataset(4)])).
ml_word('smoothie', noun, forms(['smoothie', 'smoothies']), demand([question_corpus(1), supplement_class('common_noun')])).
ml_word('snack', noun, forms(['snack', 'snacks']), demand([question_corpus(1), dataset(30)])).
ml_word('snail', noun, forms(['snail', 'snails']), demand([dataset(62)])).
ml_word('snake', noun, forms(['snake', 'snakes']), demand([question_corpus(1), dataset(5)])).
ml_word('snake', verb, forms(['snake', 'snaked', 'snakes', 'snaking']), demand([question_corpus(1), dataset(5)])).
ml_word('snap', noun, forms(['snap', 'snaps']), demand([question_corpus(2)])).
ml_word('snap', verb, forms(['snap', 'snaped', 'snaping', 'snapped', 'snapping', 'snaps']), demand([question_corpus(2)])).
ml_word('sneaker', noun, forms(['sneaker', 'sneakers']), demand([dataset(12)])).
ml_word('snow', noun, forms(['snow', 'snows']), demand([question_corpus(1), dataset(12)])).
ml_word('snow', verb, forms(['snow', 'snowed', 'snowing', 'snows']), demand([question_corpus(1), dataset(12)])).
ml_word('soak', verb, forms(['soak', 'soaked', 'soaking', 'soaks']), demand([dataset(2)])).
ml_word('soap', noun, forms(['soap', 'soaps']), demand([dataset(28)])).
ml_word('soap', verb, forms(['soap', 'soaped', 'soaping', 'soaps']), demand([dataset(28)])).
ml_word('soccer', noun, forms(['soccer']), demand([question_corpus(1), dataset(68), supplement_class('common_noun')])).
ml_word('social', adjective, forms(['social']), demand([dataset(6)])).
ml_word('sock', noun, forms(['sock', 'socks']), demand([question_corpus(2), dataset(93)])).
ml_word('soda', noun, forms(['soda', 'sodas']), demand([dataset(33)])).
ml_word('sofa', noun, forms(['sofa', 'sofas']), demand([dataset(3)])).
ml_word('sofia', given_name, forms(['sofia']), demand([dataset(5), supplement_class('given_name')])).
ml_word('soft', noun, forms(['soft', 'softs']), demand([dataset(11)])).
ml_word('soft', adjective, forms(['soft', 'softer', 'softest']), demand([dataset(11)])).
ml_word('soft', adverb, forms(['soft']), demand([dataset(11)])).
ml_word('soft', interjection, forms(['soft']), demand([dataset(11)])).
ml_word('softball', noun, forms(['softball', 'softballs']), demand([dataset(14), supplement_class('common_noun')])).
ml_word('sold', noun, forms(['sold', 'solds']), demand([question_corpus(1), dataset(367)])).
ml_word('soldier', noun, forms(['soldier', 'soldiers']), demand([dataset(2)])).
ml_word('soldier', verb, forms(['soldier', 'soldiered', 'soldiering', 'soldiers']), demand([dataset(2)])).
ml_word('solid', noun, forms(['solid', 'solids']), demand([question_corpus(4)])).
ml_word('solid', adjective, forms(['solid']), demand([question_corpus(4)])).
ml_word('solo', noun, forms(['soli', 'solo', 'solos']), demand([dataset(18)])).
ml_word('solution', noun, forms(['solution', 'solutions']), demand([question_corpus(13), dataset(6)])).
ml_word('solve', noun, forms(['solve', 'solves']), demand([question_corpus(17), dataset(23)])).
ml_word('solve', verb, forms(['solve', 'solved', 'solves', 'solving']), demand([question_corpus(28), dataset(66)])).
ml_word('someone', function_word, forms(['someone']), demand([question_corpus(8), dataset(12), supplement_class('function_word')])).
ml_word('something', noun, forms(['something', 'somethings']), demand([question_corpus(6), dataset(13)])).
ml_word('sometimes', adjective, forms(['sometimes']), demand([question_corpus(1)])).
ml_word('sometimes', adverb, forms(['sometimes']), demand([question_corpus(1)])).
ml_word('son', noun, forms(['son', 'sons']), demand([dataset(4)])).
ml_word('song', noun, forms(['song', 'songs']), demand([dataset(28)])).
ml_word('sonja', given_name, forms(['sonja']), demand([dataset(10), supplement_class('given_name')])).
ml_word('soon', adjective, forms(['soon']), demand([dataset(4)])).
ml_word('soon', adverb, forms(['soon']), demand([dataset(4)])).
ml_word('sophia', given_name, forms(['sophia']), demand([dataset(28), supplement_class('given_name')])).
ml_word('sort', noun, forms(['sort', 'sorts']), demand([question_corpus(2), dataset(4)])).
ml_word('sort', verb, forms(['sort', 'sorted', 'sorting', 'sorts']), demand([question_corpus(2), dataset(4)])).
ml_word('sound', noun, forms(['sound', 'sounds']), demand([question_corpus(1)])).
ml_word('sound', verb, forms(['sound', 'sounded', 'sounding', 'sounds']), demand([question_corpus(1)])).
ml_word('sound', adjective, forms(['sound', 'sounder', 'soundest']), demand([question_corpus(1)])).
ml_word('sound', adverb, forms(['sound']), demand([question_corpus(1)])).
ml_word('sour', noun, forms(['sour', 'sours']), demand([question_corpus(1)])).
ml_word('sour', verb, forms(['sour', 'soured', 'souring', 'sours']), demand([question_corpus(1)])).
ml_word('sour', adjective, forms(['sour', 'sourer', 'sourest']), demand([question_corpus(1)])).
ml_word('sourdough', noun, forms(['sourdough']), demand([dataset(5), supplement_class('common_noun')])).
ml_word('south', verb, forms(['south', 'southed', 'southing', 'souths']), demand([dataset(6)])).
ml_word('south', adjective, forms(['south']), demand([dataset(6)])).
ml_word('space', noun, forms(['space', 'spaces']), demand([question_corpus(2), dataset(61)])).
ml_word('space', verb, forms(['space', 'spaced', 'spaces', 'spacing', 'spacong']), demand([question_corpus(2), dataset(61)])).
ml_word('spacecraft', noun, forms(['spacecraft']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('spain', place_name, forms(['spain']), demand([dataset(12), supplement_class('place_name')])).
ml_word('spare', noun, forms(['spare', 'spares']), demand([dataset(3)])).
ml_word('spare', verb, forms(['spare', 'spared', 'spares', 'sparing']), demand([dataset(3)])).
ml_word('spare', adjective, forms(['spare', 'sparer', 'sparest']), demand([dataset(3)])).
ml_word('speak', verb, forms(['speak', 'speaking', 'speaks', 'spoke', 'spoken']), demand([question_corpus(1)])).
ml_word('special', noun, forms(['special', 'specials']), demand([question_corpus(1), dataset(4)])).
ml_word('special', adjective, forms(['special']), demand([question_corpus(1), dataset(4)])).
ml_word('specialist', noun, forms(['specialist', 'specialists']), demand([dataset(18)])).
ml_word('specialization', noun, forms(['specialization', 'specializations']), demand([dataset(1)])).
ml_word('specialize', verb, forms(['specialize', 'specialized', 'specializes', 'specializing']), demand([dataset(5)])).
ml_word('specie', noun, forms(['specie', 'species']), demand([question_corpus(1), dataset(2)])).
ml_word('specific', noun, forms(['specific', 'specifics']), demand([question_corpus(4)])).
ml_word('specific', adjective, forms(['specific']), demand([question_corpus(4)])).
ml_word('speed', noun, forms(['speed', 'speeds']), demand([question_corpus(3), dataset(72)])).
ml_word('speed', verb, forms(['sped', 'speed', 'speeded', 'speeding', 'speeds']), demand([question_corpus(3), dataset(72)])).
ml_word('spend', verb, forms(['spend', 'spended', 'spending', 'spends', 'spent']), demand([question_corpus(2), dataset(688)])).
ml_word('spending', noun, forms(['spending', 'spendings']), demand([dataset(21)])).
ml_word('spent', adjective, forms(['spent']), demand([question_corpus(1), dataset(297)])).
ml_word('sphere', noun, forms(['sphere', 'spheres']), demand([question_corpus(1)])).
ml_word('sphere', verb, forms(['sphere', 'sphered', 'spheres', 'sphering']), demand([question_corpus(1)])).
ml_word('spherics', noun, forms(['spherics', 'sphericses']), demand([webster_domain('math')])).
ml_word('spheroconic', noun, forms(['spheroconic', 'spheroconics']), demand([webster_domain('geom')])).
ml_word('spicy', adjective, forms(['spicier', 'spiciest', 'spicy']), demand([question_corpus(1), dataset(2)])).
ml_word('spider', noun, forms(['spider', 'spiders']), demand([dataset(14)])).
ml_word('spiderweb', noun, forms(['spiderweb', 'spiderwebs']), demand([dataset(7), supplement_class('common_noun')])).
ml_word('spill', noun, forms(['spill', 'spills']), demand([question_corpus(1), dataset(11)])).
ml_word('spill', verb, forms(['spill', 'spilled', 'spilling', 'spills', 'spilt']), demand([question_corpus(1), dataset(15)])).
ml_word('splash', noun, forms(['splash', 'splashes']), demand([dataset(10)])).
ml_word('splash', verb, forms(['splash', 'splashed', 'splashes', 'splashing']), demand([dataset(10)])).
ml_word('split', noun, forms(['split', 'splits']), demand([question_corpus(1), dataset(57)])).
ml_word('split', verb, forms(['split', 'splited', 'spliting', 'splits', 'splitting']), demand([question_corpus(1), dataset(59), supplement_class('corpus_verb')])).
ml_word('split', adjective, forms(['split']), demand([question_corpus(1), dataset(54)])).
ml_word('spoken', adjective, forms(['spoken']), demand([question_corpus(1)])).
ml_word('spoon', noun, forms(['spoon', 'spoons']), demand([question_corpus(1), dataset(184)])).
ml_word('spoon', verb, forms(['spoon', 'spooned', 'spooning', 'spoons']), demand([question_corpus(1), dataset(184)])).
ml_word('sport', noun, forms(['sport', 'sports']), demand([question_corpus(3), dataset(5)])).
ml_word('sport', verb, forms(['sport', 'sported', 'sporting', 'sports']), demand([question_corpus(3), dataset(5)])).
ml_word('spot', noun, forms(['spot', 'spots']), demand([question_corpus(1)])).
ml_word('spot', verb, forms(['spot', 'spoted', 'spoting', 'spots', 'spotted', 'spotting']), demand([question_corpus(1)])).
ml_word('spotify', named_entity, forms(['spotify']), demand([dataset(4), supplement_class('named_entity')])).
ml_word('sprain', noun, forms(['sprain', 'sprains']), demand([dataset(4)])).
ml_word('sprain', verb, forms(['sprain', 'sprained', 'spraining', 'sprains']), demand([dataset(20)])).
ml_word('spray', noun, forms(['spray', 'sprays']), demand([dataset(7)])).
ml_word('spray', verb, forms(['spray', 'sprayed', 'spraying', 'sprays']), demand([dataset(7)])).
ml_word('spread', noun, forms(['spread', 'spreads']), demand([question_corpus(2), dataset(6)])).
ml_word('spread', verb, forms(['spread', 'spreaded', 'spreading', 'spreads']), demand([question_corpus(2), dataset(6)])).
ml_word('spreadsheet', noun, forms(['spreadsheet', 'spreadsheets']), demand([question_corpus(1), supplement_class('common_noun')])).
ml_word('sprig', noun, forms(['sprig', 'sprigs']), demand([dataset(58)])).
ml_word('sprig', verb, forms(['sprig', 'sprigged', 'sprigging', 'sprigs']), demand([dataset(58)])).
ml_word('spring', noun, forms(['spring', 'springs']), demand([dataset(8)])).
ml_word('spring', verb, forms(['sprang', 'spring', 'springing', 'springs', 'sprung']), demand([dataset(8)])).
ml_word('sprite', noun, forms(['sprite', 'sprites']), demand([dataset(4)])).
ml_word('sprout', noun, forms(['sprout', 'sprouts']), demand([dataset(13)])).
ml_word('sprout', verb, forms(['sprout', 'sprouted', 'sprouting', 'sprouts']), demand([dataset(13)])).
ml_word('sq', unit_abbreviation, forms(['sq']), demand([question_corpus(1), dataset(7), supplement_class('unit_abbreviation')])).
ml_word('sqrt', math_notation, forms(['sqrt']), demand([dataset(2), supplement_class('math_notation')])).
ml_word('squab', noun, forms(['squab', 'squabs']), demand([dataset(2)])).
ml_word('squab', verb, forms(['squab', 'squabed', 'squabing', 'squabs']), demand([dataset(2)])).
ml_word('square', noun, forms(['square', 'squares']), demand([question_corpus(16), dataset(152), questioning_paper_lexicon])).
ml_word('square', verb, forms(['square', 'squared', 'squares', 'squaring']), demand([question_corpus(17), dataset(152), questioning_paper_lexicon])).
ml_word('square', adjective, forms(['square']), demand([question_corpus(8), dataset(152), questioning_paper_lexicon])).
ml_word('squeeze', noun, forms(['squeeze', 'squeezes']), demand([question_corpus(1)])).
ml_word('squeeze', verb, forms(['squeeze', 'squeezed', 'squeezes', 'squeezing']), demand([question_corpus(1)])).
ml_word('squirrel', noun, forms(['squirrel', 'squirrels']), demand([dataset(52), supplement_class('common_noun')])).
ml_word('sr', honorific, forms(['sr']), demand([dataset(1), supplement_class('honorific')])).
ml_word('stack', verb, forms(['stack', 'stacked', 'stacking', 'stacks']), demand([dataset(6)])).
ml_word('stack', adjective, forms(['stack']), demand([dataset(2)])).
ml_word('stacking', noun, forms(['stacking', 'stackings']), demand([dataset(2)])).
ml_word('stacking', adjective, forms(['stacking']), demand([dataset(2)])).
ml_word('stage', noun, forms(['stage', 'stages']), demand([dataset(36)])).
ml_word('stage', verb, forms(['stage', 'staged', 'stages', 'staging']), demand([dataset(36)])).
ml_word('stair', noun, forms(['stair', 'stairs']), demand([dataset(28)])).
ml_word('stamp', noun, forms(['stamp', 'stamps']), demand([dataset(8)])).
ml_word('stamp', verb, forms(['stamp', 'stamped', 'stamping', 'stamps']), demand([dataset(12)])).
ml_word('stamping', noun, forms(['stamping', 'stampings']), demand([dataset(4)])).
ml_word('stamping', adjective, forms(['stamping']), demand([dataset(4)])).
ml_word('stand', noun, forms(['stand', 'stands']), demand([question_corpus(1), dataset(30)])).
ml_word('stand', verb, forms(['stand', 'standed', 'standing', 'stands', 'stood']), demand([question_corpus(1), dataset(32)])).
ml_word('standard', noun, forms(['standard', 'standards']), demand([question_corpus(2), dataset(5)])).
ml_word('standard', adjective, forms(['standard']), demand([question_corpus(2), dataset(5)])).
ml_word('standing', noun, forms(['standing', 'standings']), demand([dataset(2)])).
ml_word('standing', adjective, forms(['standing']), demand([dataset(2)])).
ml_word('star', noun, forms(['star', 'stars']), demand([dataset(24)])).
ml_word('star', verb, forms(['star', 'stared', 'staring', 'starred', 'starring', 'stars']), demand([dataset(24)])).
ml_word('start', noun, forms(['start', 'starts']), demand([question_corpus(7), dataset(194)])).
ml_word('start', verb, forms(['start', 'started', 'starting', 'starts']), demand([question_corpus(15), dataset(331)])).
ml_word('starting', noun, forms(['starting', 'startings']), demand([question_corpus(3), dataset(28)])).
ml_word('starting', adjective, forms(['starting']), demand([question_corpus(3), dataset(28)])).
ml_word('stash', verb, forms(['stash', 'stashed', 'stashes', 'stashing']), demand([dataset(2), supplement_class('corpus_verb')])).
ml_word('statement', noun, forms(['statement', 'statements']), demand([question_corpus(15), dataset(3)])).
ml_word('station', noun, forms(['station', 'stations']), demand([question_corpus(1), dataset(21)])).
ml_word('station', verb, forms(['station', 'stationed', 'stationing', 'stations']), demand([question_corpus(1), dataset(21)])).
ml_word('stationery', noun, forms(['stationeries', 'stationery']), demand([dataset(8)])).
ml_word('stationery', adjective, forms(['stationery']), demand([dataset(8)])).
ml_word('statistics', noun, forms(['statistics', 'statisticses']), demand([dataset(12)])).
ml_word('stay', noun, forms(['stay', 'stays']), demand([question_corpus(7)])).
ml_word('stay', verb, forms(['staid', 'stay', 'staying', 'stays']), demand([question_corpus(7)])).
ml_word('stayed', adjective, forms(['stayed']), demand([dataset(5)])).
ml_word('steak', noun, forms(['steak', 'steaks']), demand([dataset(1)])).
ml_word('steeper', noun, forms(['steeper', 'steepers']), demand([question_corpus(1)])).
ml_word('step', noun, forms(['step', 'steps']), demand([question_corpus(4), dataset(8599)])).
ml_word('step', verb, forms(['step', 'steped', 'steping', 'stepped', 'stepping', 'steps']), demand([question_corpus(4), dataset(8599)])).
ml_word('stephen', given_name, forms(['stephen']), demand([dataset(2), supplement_class('given_name')])).
ml_word('steve', verb, forms(['steve', 'steved', 'steves', 'steving']), demand([dataset(33)])).
ml_word('stew', noun, forms(['stew', 'stews']), demand([dataset(56)])).
ml_word('stew', verb, forms(['stew', 'stewed', 'stewing', 'stews']), demand([dataset(56)])).
ml_word('stick', noun, forms(['stick', 'sticks']), demand([dataset(8)])).
ml_word('stick', verb, forms(['stick', 'sticked', 'sticking', 'sticks', 'stuck']), demand([dataset(12)])).
ml_word('sticker', noun, forms(['sticker', 'stickers']), demand([question_corpus(2), dataset(42)])).
ml_word('sticky', adjective, forms(['stickier', 'stickiest', 'sticky']), demand([question_corpus(2), dataset(9)])).
ml_word('still', noun, forms(['still', 'stills']), demand([question_corpus(4), dataset(68)])).
ml_word('still', verb, forms(['still', 'stilled', 'stilling', 'stills']), demand([question_corpus(4), dataset(68)])).
ml_word('still', adjective, forms(['still', 'stiller', 'stillest']), demand([question_corpus(4), dataset(68)])).
ml_word('still', adverb, forms(['still']), demand([question_corpus(4), dataset(68)])).
ml_word('stock', noun, forms(['stock', 'stocks']), demand([question_corpus(1), dataset(8)])).
ml_word('stock', verb, forms(['stock', 'stocked', 'stocking', 'stocks']), demand([question_corpus(1), dataset(8)])).
ml_word('stock', adjective, forms(['stock']), demand([question_corpus(1), dataset(8)])).
ml_word('stockpile', verb, forms(['stockpile', 'stockpiled', 'stockpiles', 'stockpiling']), demand([dataset(8), supplement_class('corpus_verb')])).
ml_word('stop', noun, forms(['stop', 'stops']), demand([question_corpus(2), dataset(57)])).
ml_word('stop', verb, forms(['stop', 'stoped', 'stoping', 'stopped', 'stopping', 'stops']), demand([question_corpus(2), dataset(69)])).
ml_word('stopover', noun, forms(['stopover', 'stopovers']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('stopped', adjective, forms(['stopped']), demand([dataset(12)])).
ml_word('storage', noun, forms(['storage', 'storages']), demand([dataset(23)])).
ml_word('store', noun, forms(['store', 'stores']), demand([question_corpus(3), dataset(195)])).
ml_word('store', verb, forms(['store', 'stored', 'stores', 'storing']), demand([question_corpus(3), dataset(196)])).
ml_word('store', adjective, forms(['store']), demand([question_corpus(3), dataset(183)])).
ml_word('stored', adjective, forms(['stored']), demand([dataset(1)])).
ml_word('storm', noun, forms(['storm', 'storms']), demand([dataset(10)])).
ml_word('storm', verb, forms(['storm', 'stormed', 'storming', 'storms']), demand([dataset(10)])).
ml_word('story', noun, forms(['stories', 'story']), demand([question_corpus(35), dataset(10)])).
ml_word('story', verb, forms(['storied', 'stories', 'story', 'storying']), demand([question_corpus(35), dataset(10)])).
ml_word('straight', noun, forms(['straight', 'straights']), demand([dataset(14)])).
ml_word('straight', verb, forms(['straight', 'straighted', 'straighting', 'straights']), demand([dataset(14)])).
ml_word('straight', adjective, forms(['straight', 'straighter', 'straightest']), demand([dataset(14)])).
ml_word('straight', adverb, forms(['straight']), demand([dataset(14)])).
ml_word('strategy', noun, forms(['strategies', 'strategy']), demand([question_corpus(38)])).
ml_word('straw', noun, forms(['straw', 'straws']), demand([question_corpus(1)])).
ml_word('straw', verb, forms(['straw', 'strawed', 'strawing', 'straws']), demand([question_corpus(1)])).
ml_word('strawberry', noun, forms(['strawberries', 'strawberry']), demand([dataset(75)])).
ml_word('street', noun, forms(['street', 'streets']), demand([question_corpus(1), dataset(20)])).
ml_word('strengthen', verb, forms(['strengthen', 'strengthened', 'strengthening', 'strengthens']), demand([dataset(2)])).
ml_word('stretch', noun, forms(['stretch', 'stretches']), demand([dataset(4)])).
ml_word('stretch', verb, forms(['stretch', 'stretched', 'stretches', 'stretching']), demand([dataset(4)])).
ml_word('strictly', adverb, forms(['strictly']), demand([dataset(2)])).
ml_word('strip', noun, forms(['strip', 'strips']), demand([question_corpus(4), dataset(23)])).
ml_word('strip', verb, forms(['strip', 'striped', 'striping', 'stripped', 'stripping', 'strips']), demand([question_corpus(4), dataset(23)])).
ml_word('stripe', noun, forms(['stripe', 'stripes']), demand([dataset(100)])).
ml_word('stripe', verb, forms(['stripe', 'striped', 'stripes', 'striping']), demand([dataset(100)])).
ml_word('striploin', noun, forms(['striploin', 'striploins']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('strong', adjective, forms(['strong', 'stronger', 'strongest']), demand([question_corpus(1), dataset(4)])).
ml_word('structure', noun, forms(['structure', 'structures']), demand([question_corpus(8), dataset(11)])).
ml_word('struggle', verb, forms(['struggle', 'struggled', 'struggles', 'struggling']), demand([question_corpus(1)])).
ml_word('strut', verb, forms(['strut', 'struted', 'struting', 'struts', 'strutted', 'strutting']), demand([dataset(4)])).
ml_word('strutting', noun, forms(['strutting', 'struttings']), demand([dataset(4)])).
ml_word('strutting', adjective, forms(['strutting']), demand([dataset(4)])).
ml_word('stuart', given_name, forms(['stuart']), demand([dataset(20), supplement_class('given_name')])).
ml_word('stuck', noun, forms(['stuck', 'stucks']), demand([dataset(4)])).
ml_word('studied', adjective, forms(['studied']), demand([dataset(3)])).
ml_word('study', noun, forms(['studies', 'study']), demand([dataset(34)])).
ml_word('study', verb, forms(['studied', 'studies', 'study', 'studying']), demand([dataset(44)])).
ml_word('stuff', verb, forms(['stuff', 'stuffed', 'stuffing', 'stuffs']), demand([dataset(6)])).
ml_word('stylist', noun, forms(['stylist', 'stylists']), demand([dataset(6)])).
ml_word('sublet', verb, forms(['sublet', 'sublets', 'subletting']), demand([dataset(9)])).
ml_word('submit', verb, forms(['submit', 'submited', 'submiting', 'submits', 'submitted', 'submitting']), demand([dataset(2)])).
ml_word('submultiple', noun, forms(['submultiple', 'submultiples']), demand([webster_domain('math')])).
ml_word('submultiple', adjective, forms(['submultiple']), demand([webster_domain('math')])).
ml_word('subnormal', noun, forms(['subnormal', 'subnormals']), demand([webster_domain('geom')])).
ml_word('subscription', noun, forms(['subscription', 'subscriptions']), demand([dataset(11)])).
ml_word('subsequent', adjective, forms(['subsequent']), demand([dataset(5)])).
ml_word('subside', verb, forms(['subside', 'subsided', 'subsides', 'subsiding']), demand([dataset(4)])).
ml_word('substitute', noun, forms(['substitute', 'substitutes']), demand([dataset(8)])).
ml_word('substitute', verb, forms(['substitute', 'substituted', 'substitutes', 'substituting']), demand([dataset(13)])).
ml_word('substitution', noun, forms(['substitution', 'substitutions']), demand([dataset(1)])).
ml_word('subtangent', noun, forms(['subtangent', 'subtangents']), demand([webster_domain('geom')])).
ml_word('subtract', verb, forms(['subtract', 'subtracted', 'subtracting', 'subtracts']), demand([question_corpus(19), dataset(124)])).
ml_word('subtraction', noun, forms(['subtraction', 'subtractions']), demand([question_corpus(8), questioning_paper_lexicon])).
ml_word('success', noun, forms(['success', 'successes']), demand([question_corpus(2)])).
ml_word('successful', adjective, forms(['successful']), demand([question_corpus(2)])).
ml_word('such', adjective, forms(['such']), demand([question_corpus(1), dataset(6)])).
ml_word('suddenly', adverb, forms(['suddenly']), demand([dataset(2), supplement_class('adverb')])).
ml_word('suffer', verb, forms(['suffer', 'suffered', 'suffering', 'suffers']), demand([dataset(2)])).
ml_word('suffering', noun, forms(['suffering', 'sufferings']), demand([dataset(2)])).
ml_word('suffering', adjective, forms(['suffering']), demand([dataset(2)])).
ml_word('sugar', noun, forms(['sugar', 'sugars']), demand([dataset(46)])).
ml_word('sugar', verb, forms(['sugar', 'sugared', 'sugaring', 'sugars']), demand([dataset(46)])).
ml_word('suit', noun, forms(['suit', 'suits']), demand([dataset(12)])).
ml_word('suit', verb, forms(['suit', 'suited', 'suiting', 'suits']), demand([dataset(12)])).
ml_word('sum', noun, forms(['sum', 'sums']), demand([question_corpus(33), dataset(37), questioning_paper_lexicon])).
ml_word('sum', verb, forms(['sum', 'summed', 'summing', 'sums']), demand([question_corpus(33), dataset(37), questioning_paper_lexicon])).
ml_word('summer', noun, forms(['summer', 'summers']), demand([question_corpus(2), dataset(18)])).
ml_word('summer', verb, forms(['summer', 'summered', 'summering', 'summers']), demand([question_corpus(2), dataset(18)])).
ml_word('sunday', noun, forms(['sunday', 'sundays']), demand([dataset(42)])).
ml_word('sunday', adjective, forms(['sunday']), demand([dataset(34)])).
ml_word('sunny', noun, forms(['sunnies', 'sunny']), demand([question_corpus(1)])).
ml_word('sunny', adjective, forms(['sunnier', 'sunniest', 'sunny']), demand([question_corpus(1)])).
ml_word('sunscreen', noun, forms(['sunscreen']), demand([dataset(4), supplement_class('common_noun')])).
ml_word('supercharge', noun, forms(['supercharge', 'supercharges']), demand([dataset(3)])).
ml_word('supercharge', verb, forms(['supercharge', 'supercharged', 'supercharges', 'supercharging']), demand([dataset(3)])).
ml_word('supermajority', noun, forms(['supermajorities', 'supermajority']), demand([question_corpus(1), supplement_class('common_noun')])).
ml_word('supplementary', adjective, forms(['supplementary']), demand([question_corpus(1)])).
ml_word('supply', noun, forms(['supplies', 'supply']), demand([dataset(35)])).
ml_word('supply', verb, forms(['supplied', 'supplies', 'supply', 'supplying']), demand([dataset(35)])).
ml_word('supply', adjective, forms(['supply']), demand([dataset(10)])).
ml_word('support', noun, forms(['support', 'supports']), demand([question_corpus(6)])).
ml_word('support', verb, forms(['support', 'supported', 'supporting', 'supports']), demand([question_corpus(8), dataset(7)])).
ml_word('suppose', noun, forms(['suppose', 'supposes']), demand([question_corpus(1)])).
ml_word('suppose', verb, forms(['suppose', 'supposed', 'supposes', 'supposing']), demand([question_corpus(1), dataset(26)])).
ml_word('surd', noun, forms(['surd', 'surds']), demand([webster_domain('math')])).
ml_word('surd', adjective, forms(['surd']), demand([webster_domain('math')])).
ml_word('sure', adjective, forms(['sure', 'surer', 'surest']), demand([question_corpus(6), dataset(18)])).
ml_word('sure', adverb, forms(['sure']), demand([question_corpus(6), dataset(18)])).
ml_word('surface', noun, forms(['surface', 'surfaces']), demand([question_corpus(5), dataset(12)])).
ml_word('surface', verb, forms(['surface', 'surfaced', 'surfaces', 'surfacing']), demand([question_corpus(6), dataset(12)])).
ml_word('surprise', verb, forms(['surprise', 'surprised', 'surprises', 'surprising']), demand([question_corpus(4)])).
ml_word('surprising', adjective, forms(['surprising']), demand([question_corpus(1)])).
ml_word('survey', noun, forms(['survey', 'surveys']), demand([dataset(6)])).
ml_word('survey', verb, forms(['survey', 'surveyed', 'surveying', 'surveys']), demand([dataset(6)])).
ml_word('surveyor', noun, forms(['surveyor', 'surveyors']), demand([dataset(2)])).
ml_word('survive', verb, forms(['survive', 'survived', 'survives', 'surviving']), demand([dataset(11)])).
ml_word('surviving', adjective, forms(['surviving']), demand([dataset(1)])).
ml_word('susan', given_name, forms(['susan']), demand([dataset(6), supplement_class('given_name')])).
ml_word('sustain', noun, forms(['sustain', 'sustains']), demand([dataset(4)])).
ml_word('sustain', verb, forms(['sustain', 'sustained', 'sustaining', 'sustains']), demand([dataset(4)])).
ml_word('sustainably', adverb, forms(['sustainably']), demand([dataset(3), supplement_class('adverb')])).
ml_word('suv', abbreviation, forms(['suv']), demand([dataset(15), supplement_class('abbreviation')])).
ml_word('swath', noun, forms(['swath', 'swaths']), demand([dataset(5)])).
ml_word('sweep', verb, forms(['sweep', 'sweeped', 'sweeping', 'sweeps', 'swept']), demand([dataset(12)])).
ml_word('sweeping', adjective, forms(['sweeping']), demand([dataset(6)])).
ml_word('sweet', noun, forms(['sweet', 'sweets']), demand([question_corpus(1)])).
ml_word('sweet', verb, forms(['sweet', 'sweeted', 'sweeting', 'sweets']), demand([question_corpus(1)])).
ml_word('sweet', adjective, forms(['sweet', 'sweeter', 'sweetest']), demand([question_corpus(1)])).
ml_word('sweet', adverb, forms(['sweet']), demand([question_corpus(1)])).
ml_word('swim', noun, forms(['swim', 'swims']), demand([dataset(14)])).
ml_word('swim', verb, forms(['swam', 'swim', 'swimed', 'swiming', 'swimming', 'swims', 'swum']), demand([dataset(20)])).
ml_word('swimming', noun, forms(['swimming', 'swimmings']), demand([dataset(6)])).
ml_word('swimming', adjective, forms(['swimming']), demand([dataset(6)])).
ml_word('swing', noun, forms(['swing', 'swings']), demand([question_corpus(3)])).
ml_word('swing', verb, forms(['swang', 'swing', 'swinged', 'swinging', 'swings', 'swung']), demand([question_corpus(3)])).
ml_word('symbol', noun, forms(['symbol', 'symbols']), demand([question_corpus(2)])).
ml_word('symbol', verb, forms(['symbol', 'symboled', 'symboling', 'symbols']), demand([question_corpus(2)])).
ml_word('symmetrical', adjective, forms(['symmetrical']), demand([question_corpus(1)])).
ml_word('symmetry', noun, forms(['symmetries', 'symmetry']), demand([question_corpus(3), questioning_paper_lexicon])).
ml_word('syrup', noun, forms(['syrup', 'syrups']), demand([dataset(36)])).
ml_word('system', noun, forms(['system', 'systems']), demand([question_corpus(3), dataset(37)])).
ml_word('tabitha', given_name, forms(['tabitha']), demand([dataset(8), supplement_class('given_name')])).
ml_word('table', noun, forms(['table', 'tables']), demand([question_corpus(18), dataset(30)])).
ml_word('table', verb, forms(['table', 'tabled', 'tableed', 'tableing', 'tables', 'tabling']), demand([question_corpus(18), dataset(30)])).
ml_word('tablespoon', noun, forms(['tablespoon', 'tablespoons']), demand([question_corpus(1), dataset(32)])).
ml_word('taco', noun, forms(['taco', 'tacos']), demand([dataset(24), supplement_class('common_noun')])).
ml_word('tadpole', noun, forms(['tadpole', 'tadpoles']), demand([dataset(15)])).
ml_word('taffy', noun, forms(['taffies', 'taffy']), demand([dataset(24)])).
ml_word('tail', noun, forms(['tail', 'tails']), demand([dataset(9)])).
ml_word('tail', verb, forms(['tail', 'tailed', 'tailing', 'tails']), demand([dataset(9)])).
ml_word('tail', adjective, forms(['tail']), demand([dataset(9)])).
ml_word('tailor', verb, forms(['tailor', 'tailored', 'tailoring', 'tailors']), demand([dataset(8)])).
ml_word('tailoring', adverb, forms(['tailoring']), demand([dataset(8)])).
ml_word('take', noun, forms(['take', 'takes']), demand([question_corpus(11), dataset(718)])).
ml_word('take', verb, forms(['take', 'taken', 'takend', 'takes', 'taking', 'took']), demand([question_corpus(15), dataset(976), supplement_class('corpus_verb')])).
ml_word('taking', noun, forms(['taking', 'takings']), demand([dataset(43)])).
ml_word('taking', adjective, forms(['taking']), demand([dataset(43)])).
ml_word('talent', noun, forms(['talent', 'talents']), demand([dataset(20)])).
ml_word('talia', given_name, forms(['talia']), demand([dataset(50), supplement_class('given_name')])).
ml_word('talk', noun, forms(['talk', 'talks']), demand([question_corpus(2)])).
ml_word('talk', verb, forms(['talk', 'talked', 'talking', 'talks']), demand([question_corpus(2)])).
ml_word('tall', adjective, forms(['tall', 'taller', 'tallest']), demand([question_corpus(4), dataset(30)])).
ml_word('tammy', noun, forms(['tammies', 'tammy']), demand([dataset(4)])).
ml_word('tania', given_name, forms(['tania']), demand([dataset(2), supplement_class('given_name')])).
ml_word('tank', noun, forms(['tank', 'tanks']), demand([dataset(117)])).
ml_word('tanya', given_name, forms(['tanya']), demand([dataset(22), supplement_class('given_name')])).
ml_word('tap', noun, forms(['tap', 'taps']), demand([dataset(6)])).
ml_word('tap', verb, forms(['tap', 'taped', 'taping', 'tapped', 'tapping', 'taps']), demand([dataset(6)])).
ml_word('tape', noun, forms(['tape', 'tapes']), demand([question_corpus(3), questioning_paper_lexicon])).
ml_word('taper', verb, forms(['taper', 'tapered', 'tapering', 'tapers']), demand([dataset(6)])).
ml_word('tapered', adjective, forms(['tapered']), demand([dataset(6)])).
ml_word('tara', given_name, forms(['tara']), demand([dataset(2), supplement_class('given_name')])).
ml_word('target', noun, forms(['target', 'targets']), demand([dataset(40)])).
ml_word('tariff', noun, forms(['tariff', 'tariffs', 'tarives']), demand([dataset(3)])).
ml_word('tariff', verb, forms(['tariff', 'tariffed', 'tariffing', 'tariffs']), demand([dataset(3)])).
ml_word('tasha', given_name, forms(['tasha']), demand([dataset(8), supplement_class('given_name')])).
ml_word('task', noun, forms(['task', 'tasks']), demand([question_corpus(1), dataset(17)])).
ml_word('task', verb, forms(['task', 'tasked', 'tasking', 'tasks']), demand([question_corpus(1), dataset(17)])).
ml_word('taste', noun, forms(['taste', 'tastes']), demand([question_corpus(1)])).
ml_word('taste', verb, forms(['taste', 'tasted', 'tastes', 'tasting']), demand([question_corpus(1)])).
ml_word('taught', adjective, forms(['taught']), demand([dataset(28)])).
ml_word('tavern', noun, forms(['tavern', 'taverns']), demand([dataset(1)])).
ml_word('tavernmaster', noun, forms(['tavernmaster', 'tavernmasters']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('tax', noun, forms(['tax', 'taxes']), demand([question_corpus(1), dataset(24)])).
ml_word('tax', verb, forms(['tax', 'taxed', 'taxes', 'taxing']), demand([question_corpus(1), dataset(24)])).
ml_word('tayzia', given_name, forms(['tayzia']), demand([dataset(15), supplement_class('given_name')])).
ml_word('tea', noun, forms(['tea', 'teas']), demand([dataset(59)])).
ml_word('tea', verb, forms(['tea', 'teaed', 'teaing', 'teas']), demand([dataset(59)])).
ml_word('teach', verb, forms(['taught', 'teach', 'teached', 'teaches', 'teaching']), demand([question_corpus(6), dataset(44)])).
ml_word('teache', noun, forms(['teache', 'teaches']), demand([dataset(10)])).
ml_word('teacher', noun, forms(['teacher', 'teachers']), demand([dataset(33)])).
ml_word('teaching', noun, forms(['teaching', 'teachings']), demand([question_corpus(1), dataset(2)])).
ml_word('team', noun, forms(['team', 'teams']), demand([question_corpus(1), dataset(52)])).
ml_word('team', verb, forms(['team', 'teamed', 'teaming', 'teams']), demand([question_corpus(1), dataset(52)])).
ml_word('teammate', noun, forms(['teammate', 'teammates']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('teddy', noun, forms(['teddies', 'teddy']), demand([question_corpus(1), dataset(12), supplement_class('common_noun')])).
ml_word('tedra', given_name, forms(['tedra']), demand([dataset(8), supplement_class('given_name')])).
ml_word('teenage', noun, forms(['teenage', 'teenages']), demand([dataset(9)])).
ml_word('television', noun, forms(['television', 'televisions']), demand([question_corpus(1), dataset(45), supplement_class('common_noun')])).
ml_word('tell', noun, forms(['tell', 'tells']), demand([question_corpus(24), dataset(4)])).
ml_word('tell', verb, forms(['tell', 'telling', 'tells', 'told']), demand([question_corpus(24), dataset(20)])).
ml_word('telling', adjective, forms(['telling']), demand([dataset(4)])).
ml_word('temperature', noun, forms(['temperature', 'temperatures']), demand([question_corpus(6)])).
ml_word('ten', noun, forms(['ten', 'tens']), demand([question_corpus(22), dataset(35), questioning_paper_lexicon])).
ml_word('ten', adjective, forms(['ten']), demand([question_corpus(10), dataset(35), questioning_paper_lexicon])).
ml_word('tend', verb, forms(['tend', 'tended', 'tending', 'tends']), demand([question_corpus(1)])).
ml_word('tennis', noun, forms(['tennis', 'tennises']), demand([dataset(41)])).
ml_word('tennis', verb, forms(['tennis', 'tennised', 'tennises', 'tennising']), demand([dataset(41)])).
ml_word('tenth', noun, forms(['tenth', 'tenths']), demand([question_corpus(5), dataset(3)])).
ml_word('tenth', adjective, forms(['tenth']), demand([question_corpus(3)])).
ml_word('term', noun, forms(['term', 'terms']), demand([question_corpus(10), dataset(17)])).
ml_word('term', verb, forms(['term', 'termed', 'terming', 'terms']), demand([question_corpus(10), dataset(17)])).
ml_word('terrier', noun, forms(['terrier', 'terriers']), demand([dataset(20)])).
ml_word('tessellate', verb, forms(['tessellate', 'tessellated', 'tessellates', 'tessellating']), demand([question_corpus(2)])).
ml_word('tessellate', adjective, forms(['tessellate']), demand([question_corpus(2)])).
ml_word('tessellation', noun, forms(['tessellation', 'tessellations']), demand([question_corpus(1)])).
ml_word('test', noun, forms(['test', 'tests', 'testæ']), demand([dataset(41)])).
ml_word('test', verb, forms(['test', 'tested', 'testing', 'tests']), demand([dataset(41)])).
ml_word('testa', noun, forms(['testa', 'testas', 'tests', 'testæ']), demand([dataset(27)])).
ml_word('text', noun, forms(['text', 'texts']), demand([question_corpus(1), dataset(60)])).
ml_word('text', verb, forms(['text', 'texted', 'texting', 'texts']), demand([question_corpus(1), dataset(60)])).
ml_word('textbook', noun, forms(['textbook', 'textbooks']), demand([dataset(26), supplement_class('common_noun')])).
ml_word('thank', noun, forms(['thank', 'thanks']), demand([dataset(8)])).
ml_word('thank', verb, forms(['thank', 'thanked', 'thanking', 'thanks']), demand([dataset(8)])).
ml_word('theater', noun, forms(['theater', 'theaters']), demand([dataset(10)])).
ml_word('theatre', noun, forms(['theatre', 'theatres']), demand([dataset(2)])).
ml_word('theirs', function_word, forms(['theirs']), demand([question_corpus(1), supplement_class('function_word')])).
ml_word('theme', noun, forms(['theme', 'themes']), demand([dataset(7)])).
ml_word('themed', adjective, forms(['themed']), demand([dataset(13), supplement_class('adjective')])).
ml_word('themselves', pronoun, forms(['themselves']), demand([dataset(2)])).
ml_word('therefore', adverb, forms(['therefore']), demand([dataset(630)])).
ml_word('therefore', conjunction, forms(['therefore']), demand([dataset(630)])).
ml_word('thermometer', noun, forms(['thermometer', 'thermometers']), demand([question_corpus(1)])).
ml_word('thing', noun, forms(['thing', 'things']), demand([question_corpus(36), dataset(7)])).
ml_word('think', verb, forms(['think', 'thinking', 'thinks', 'thought']), demand([question_corpus(97), dataset(19)])).
ml_word('thinking', noun, forms(['thinking', 'thinkings']), demand([question_corpus(20), dataset(8)])).
ml_word('thinking', adjective, forms(['thinking']), demand([question_corpus(20), dataset(8)])).
ml_word('third', noun, forms(['third', 'thirds']), demand([question_corpus(19), dataset(195)])).
ml_word('third', adjective, forms(['third']), demand([question_corpus(15), dataset(183)])).
ml_word('thirty', noun, forms(['thirties', 'thirty']), demand([dataset(9)])).
ml_word('thirty', adjective, forms(['thirty']), demand([dataset(9)])).
ml_word('though', adverb, forms(['though']), demand([question_corpus(2), dataset(4)])).
ml_word('thought', noun, forms(['thought', 'thoughts']), demand([question_corpus(4), dataset(5)])).
ml_word('thousand', noun, forms(['thousand', 'thousands']), demand([dataset(2)])).
ml_word('thousand', adjective, forms(['thousand']), demand([dataset(2)])).
ml_word('thousandth', noun, forms(['thousandth', 'thousandths']), demand([question_corpus(1)])).
ml_word('thrice', adverb, forms(['thrice']), demand([dataset(6)])).
ml_word('through', adjective, forms(['through']), demand([question_corpus(1), dataset(63)])).
ml_word('through', adverb, forms(['through']), demand([question_corpus(1), dataset(63)])).
ml_word('through', preposition, forms(['through']), demand([question_corpus(1), dataset(63)])).
ml_word('throughout', adverb, forms(['throughout']), demand([question_corpus(2), dataset(5)])).
ml_word('throughout', preposition, forms(['throughout']), demand([question_corpus(2), dataset(5)])).
ml_word('throw', noun, forms(['throw', 'throws']), demand([question_corpus(1), dataset(3)])).
ml_word('throw', verb, forms(['threw', 'throw', 'throwed', 'throwing', 'thrown', 'throws']), demand([question_corpus(1), dataset(10)])).
ml_word('thumbtack', noun, forms(['thumbtack', 'thumbtacks']), demand([dataset(3), supplement_class('common_noun')])).
ml_word('thursday', noun, forms(['thursday', 'thursdays']), demand([dataset(73)])).
ml_word('thus', noun, forms(['thus', 'thuses']), demand([dataset(165)])).
ml_word('thus', adverb, forms(['thus']), demand([dataset(165)])).
ml_word('tick', noun, forms(['tick', 'ticks']), demand([question_corpus(9)])).
ml_word('tick', verb, forms(['tick', 'ticked', 'ticking', 'ticks']), demand([question_corpus(9)])).
ml_word('ticket', noun, forms(['ticket', 'tickets']), demand([question_corpus(1), dataset(222)])).
ml_word('ticket', verb, forms(['ticket', 'ticketed', 'ticketing', 'tickets']), demand([question_corpus(1), dataset(222)])).
ml_word('tie', noun, forms(['tie', 'ties']), demand([dataset(9)])).
ml_word('tie', verb, forms(['tie', 'tied', 'ties', 'tying']), demand([dataset(13)])).
ml_word('tiger', noun, forms(['tiger', 'tigers']), demand([dataset(4)])).
ml_word('tile', noun, forms(['tile', 'tiles']), demand([question_corpus(4), dataset(12)])).
ml_word('tile', verb, forms(['tile', 'tiled', 'tiles', 'tiling']), demand([question_corpus(4), dataset(12)])).
ml_word('till', noun, forms(['till', 'tills']), demand([dataset(11)])).
ml_word('till', verb, forms(['till', 'tilled', 'tilling', 'tills']), demand([dataset(13)])).
ml_word('till', preposition, forms(['till']), demand([dataset(9)])).
ml_word('till', conjunction, forms(['till']), demand([dataset(9)])).
ml_word('tiller', noun, forms(['tiller', 'tillers']), demand([dataset(3)])).
ml_word('tiller', verb, forms(['tiller', 'tillered', 'tillering', 'tillers']), demand([dataset(3)])).
ml_word('tilt', verb, forms(['tilt', 'tilted', 'tilting', 'tilts']), demand([question_corpus(1)])).
ml_word('tim', given_name, forms(['tim']), demand([dataset(24), supplement_class('given_name')])).
ml_word('time', noun, forms(['time', 'times']), demand([question_corpus(15), dataset(454)])).
ml_word('time', verb, forms(['time', 'timed', 'times', 'timing']), demand([question_corpus(15), dataset(454)])).
ml_word('timmy', given_name, forms(['timmy']), demand([dataset(9), supplement_class('given_name')])).
ml_word('tina', given_name, forms(['tina']), demand([dataset(12), supplement_class('given_name')])).
ml_word('tiny', adjective, forms(['tinier', 'tiniest', 'tiny']), demand([question_corpus(2)])).
ml_word('tip', noun, forms(['tip', 'tips']), demand([dataset(41)])).
ml_word('tip', verb, forms(['tip', 'tiped', 'tiping', 'tipped', 'tipping', 'tips']), demand([dataset(43)])).
ml_word('tipper', noun, forms(['tipper', 'tippers']), demand([dataset(7)])).
ml_word('tire', noun, forms(['tire', 'tires']), demand([dataset(95)])).
ml_word('tire', verb, forms(['tire', 'tired', 'tires', 'tiring']), demand([dataset(95)])).
ml_word('title', noun, forms(['title', 'titles']), demand([question_corpus(1)])).
ml_word('title', verb, forms(['title', 'titled', 'titles', 'titling']), demand([question_corpus(1)])).
ml_word('toast', verb, forms(['toast', 'toasted', 'toasting', 'toasts']), demand([dataset(2)])).
ml_word('toby', noun, forms(['tobies', 'toby']), demand([dataset(3)])).
ml_word('today', temporal_word, forms(['today']), demand([question_corpus(39), dataset(65), supplement_class('temporal_word')])).
ml_word('todd', given_name, forms(['todd']), demand([dataset(36), supplement_class('given_name')])).
ml_word('toddler', noun, forms(['toddler', 'toddlers']), demand([dataset(40)])).
ml_word('toe', noun, forms(['toe', 'toes']), demand([dataset(6)])).
ml_word('toe', verb, forms(['toe', 'toed', 'toeing', 'toes', 'toing']), demand([dataset(6)])).
ml_word('toenail', noun, forms(['toenail', 'toenails']), demand([dataset(40), supplement_class('common_noun')])).
ml_word('together', adverb, forms(['together']), demand([question_corpus(75), dataset(117)])).
ml_word('toilet', noun, forms(['toilet', 'toilets']), demand([dataset(42)])).
ml_word('token', noun, forms(['token', 'tokens']), demand([dataset(28)])).
ml_word('token', verb, forms(['token', 'tokened', 'tokening', 'tokens']), demand([dataset(28)])).
ml_word('tom', noun, forms(['tom', 'toms']), demand([dataset(42)])).
ml_word('tomato', noun, forms(['tomato', 'tomatoes', 'tomatos']), demand([dataset(48)])).
ml_word('tommy', noun, forms(['tommies', 'tommy']), demand([dataset(24)])).
ml_word('tomorrow', noun, forms(['tomorrow', 'tomorrows']), demand([question_corpus(3), dataset(9)])).
ml_word('tomorrow', adverb, forms(['tomorrow']), demand([question_corpus(3), dataset(9)])).
ml_word('ton', noun, forms(['ton', 'tons']), demand([dataset(33)])).
ml_word('tonight', noun, forms(['tonight', 'tonights']), demand([dataset(4)])).
ml_word('tonight', adverb, forms(['tonight']), demand([dataset(4)])).
ml_word('tony', noun, forms(['tonies', 'tony']), demand([dataset(28)])).
ml_word('tonya', given_name, forms(['tonya']), demand([dataset(9), supplement_class('given_name')])).
ml_word('too', adverb, forms(['too']), demand([question_corpus(59), dataset(16)])).
ml_word('tool', noun, forms(['tool', 'tools']), demand([question_corpus(6)])).
ml_word('tool', verb, forms(['tool', 'tooled', 'tooling', 'tools']), demand([question_corpus(6)])).
ml_word('tooth', noun, forms(['teeth', 'tooth']), demand([dataset(4)])).
ml_word('tooth', verb, forms(['tooth', 'toothed', 'toothing', 'tooths']), demand([dataset(4)])).
ml_word('top', noun, forms(['top', 'tops']), demand([question_corpus(6), dataset(45)])).
ml_word('top', verb, forms(['top', 'toped', 'toping', 'topped', 'topping', 'tops']), demand([question_corpus(6), dataset(45)])).
ml_word('total', noun, forms(['total', 'totals']), demand([question_corpus(7), dataset(1907)])).
ml_word('total', verb, forms(['total', 'totaled', 'totaling', 'totals']), demand([question_corpus(7), dataset(1910), supplement_class('corpus_verb')])).
ml_word('total', adjective, forms(['total']), demand([question_corpus(7), dataset(1907)])).
ml_word('touch', noun, forms(['touch', 'touches']), demand([dataset(12)])).
ml_word('touch', verb, forms(['touch', 'touched', 'touches', 'touching']), demand([dataset(22)])).
ml_word('touchdown', noun, forms(['touchdown', 'touchdowns']), demand([dataset(22)])).
ml_word('touching', noun, forms(['touching', 'touchings']), demand([dataset(10)])).
ml_word('touching', adjective, forms(['touching']), demand([dataset(10)])).
ml_word('touching', preposition, forms(['touching']), demand([dataset(10)])).
ml_word('toula', given_name, forms(['toula']), demand([dataset(24), supplement_class('given_name')])).
ml_word('tour', noun, forms(['tour', 'tours']), demand([dataset(5)])).
ml_word('tour', verb, forms(['tour', 'toured', 'touring', 'tours']), demand([dataset(5)])).
ml_word('tourist', noun, forms(['tourist', 'tourists']), demand([dataset(22)])).
ml_word('toward', adjective, forms(['toward']), demand([question_corpus(1)])).
ml_word('toward', preposition, forms(['toward']), demand([question_corpus(1)])).
ml_word('towards', preposition, forms(['towards']), demand([dataset(3)])).
ml_word('towel', noun, forms(['towel', 'towels']), demand([dataset(22)])).
ml_word('towel', verb, forms(['towel', 'toweled', 'toweling', 'towels']), demand([dataset(22)])).
ml_word('tower', noun, forms(['tower', 'towers']), demand([question_corpus(10), dataset(9)])).
ml_word('tower', verb, forms(['tower', 'towered', 'towering', 'towers']), demand([question_corpus(10), dataset(9)])).
ml_word('town', noun, forms(['town', 'towns']), demand([dataset(22)])).
ml_word('toy', noun, forms(['toy', 'toys']), demand([question_corpus(2), dataset(70)])).
ml_word('toy', verb, forms(['toy', 'toyed', 'toying', 'toys']), demand([question_corpus(2), dataset(70)])).
ml_word('track', noun, forms(['track', 'tracks']), demand([question_corpus(1), dataset(1)])).
ml_word('track', verb, forms(['track', 'tracked', 'tracking', 'tracks']), demand([question_corpus(1), dataset(1)])).
ml_word('tractor', noun, forms(['tractor', 'tractors']), demand([dataset(22)])).
ml_word('tracy', given_name, forms(['tracy']), demand([dataset(30), supplement_class('given_name')])).
ml_word('trade', noun, forms(['trade', 'trades']), demand([dataset(30)])).
ml_word('trade', verb, forms(['trade', 'traded', 'trades', 'trading']), demand([dataset(37)])).
ml_word('traded', adjective, forms(['traded']), demand([dataset(5)])).
ml_word('trading', adjective, forms(['trading']), demand([dataset(2)])).
ml_word('tradition', noun, forms(['tradition', 'traditions']), demand([dataset(2)])).
ml_word('tradition', verb, forms(['tradition', 'traditioned', 'traditioning', 'traditions']), demand([dataset(2)])).
ml_word('train', noun, forms(['train', 'trains']), demand([question_corpus(3), dataset(38)])).
ml_word('train', verb, forms(['train', 'trained', 'training', 'trains']), demand([question_corpus(3), dataset(54)])).
ml_word('training', noun, forms(['training', 'trainings']), demand([dataset(16)])).
ml_word('transformation', noun, forms(['transformation', 'transformations']), demand([question_corpus(4), questioning_paper_lexicon])).
ml_word('transition', noun, forms(['transition', 'transitions']), demand([question_corpus(1)])).
ml_word('transition', verb, forms(['transition', 'transitioned', 'transitioning', 'transitions']), demand([question_corpus(1), supplement_class('corpus_verb')])).
ml_word('translate', verb, forms(['translate', 'translated', 'translates', 'translating']), demand([dataset(2)])).
ml_word('translation', noun, forms(['translation', 'translations']), demand([question_corpus(2), questioning_paper_lexicon])).
ml_word('transport', noun, forms(['transport', 'transports']), demand([dataset(2)])).
ml_word('transport', verb, forms(['transport', 'transported', 'transporting', 'transports']), demand([dataset(6)])).
ml_word('transported', adjective, forms(['transported']), demand([dataset(4)])).
ml_word('trapezoid', noun, forms(['trapezoid', 'trapezoids']), demand([question_corpus(6)])).
ml_word('trapezoid', adjective, forms(['trapezoid']), demand([question_corpus(3)])).
ml_word('trash', noun, forms(['trash', 'trashes']), demand([question_corpus(3), dataset(4)])).
ml_word('trash', verb, forms(['trash', 'trashed', 'trashes', 'trashing']), demand([question_corpus(3), dataset(4)])).
ml_word('travel', noun, forms(['travel', 'travels']), demand([question_corpus(1), dataset(106)])).
ml_word('travel', verb, forms(['travel', 'traveled', 'traveling', 'travels']), demand([question_corpus(3), dataset(156)])).
ml_word('traveled', adjective, forms(['traveled']), demand([question_corpus(2), dataset(33)])).
ml_word('tray', noun, forms(['tray', 'trays']), demand([question_corpus(1), dataset(4)])).
ml_word('tray', verb, forms(['tray', 'trayed', 'traying', 'trays']), demand([question_corpus(1), dataset(4)])).
ml_word('treasure', noun, forms(['treasure', 'treasures']), demand([dataset(40)])).
ml_word('treasure', verb, forms(['treasure', 'treasured', 'treasures', 'treasuring']), demand([dataset(40)])).
ml_word('treat', noun, forms(['treat', 'treats']), demand([dataset(21)])).
ml_word('treat', verb, forms(['treat', 'treated', 'treating', 'treats']), demand([dataset(21)])).
ml_word('tree', noun, forms(['tree', 'trees']), demand([question_corpus(1), dataset(33)])).
ml_word('tree', verb, forms(['tree', 'treed', 'treeing', 'trees']), demand([question_corpus(1), dataset(33)])).
ml_word('trend', noun, forms(['trend', 'trends']), demand([question_corpus(1), dataset(4)])).
ml_word('trend', verb, forms(['trend', 'trended', 'trending', 'trends']), demand([question_corpus(1), dataset(4)])).
ml_word('trevor', given_name, forms(['trevor']), demand([dataset(32), supplement_class('given_name')])).
ml_word('trey', noun, forms(['trey', 'treys']), demand([dataset(8)])).
ml_word('triangle', noun, forms(['triangle', 'triangles']), demand([question_corpus(38), dataset(12)])).
ml_word('triangular', adjective, forms(['triangular']), demand([dataset(9)])).
ml_word('tribe', noun, forms(['tribe', 'tribes']), demand([dataset(2)])).
ml_word('tribe', verb, forms(['tribe', 'tribed', 'tribes', 'tribing']), demand([dataset(2)])).
ml_word('tricky', adjective, forms(['tricky']), demand([question_corpus(2)])).
ml_word('tricycle', noun, forms(['tricycle', 'tricycles']), demand([dataset(16)])).
ml_word('trinket', noun, forms(['trinket', 'trinkets']), demand([dataset(8)])).
ml_word('trinket', verb, forms(['trinket', 'trinketed', 'trinketing', 'trinkets']), demand([dataset(8)])).
ml_word('trip', noun, forms(['trip', 'trips']), demand([dataset(169)])).
ml_word('trip', verb, forms(['trip', 'triped', 'triping', 'tripped', 'tripping', 'trips']), demand([dataset(171), supplement_class('corpus_verb')])).
ml_word('triple', verb, forms(['triple', 'tripled', 'triples', 'tripling']), demand([dataset(26)])).
ml_word('triple', adjective, forms(['triple']), demand([dataset(17)])).
ml_word('trivia', noun, forms(['trivia']), demand([question_corpus(1), supplement_class('common_noun')])).
ml_word('troll', noun, forms(['troll', 'trolls']), demand([dataset(58)])).
ml_word('troll', verb, forms(['troll', 'trolled', 'trolling', 'trolls']), demand([dataset(58)])).
ml_word('trolley', noun, forms(['trolley', 'trolleys']), demand([dataset(22)])).
ml_word('tropical', adjective, forms(['tropical']), demand([dataset(8)])).
ml_word('trout', noun, forms(['trout', 'trouts']), demand([dataset(10)])).
ml_word('truck', noun, forms(['truck', 'trucks']), demand([question_corpus(2), dataset(51)])).
ml_word('truck', verb, forms(['truck', 'trucked', 'trucking', 'trucks']), demand([question_corpus(2), dataset(51)])).
ml_word('true', adjective, forms(['true', 'truer', 'truest']), demand([question_corpus(38)])).
ml_word('true', adverb, forms(['true']), demand([question_corpus(38)])).
ml_word('try', noun, forms(['tries', 'try']), demand([question_corpus(3), dataset(48)])).
ml_word('try', verb, forms(['tried', 'tries', 'try', 'trying']), demand([question_corpus(7), dataset(88)])).
ml_word('try', adjective, forms(['try']), demand([question_corpus(3), dataset(40)])).
ml_word('trying', adjective, forms(['trying']), demand([question_corpus(2), dataset(34)])).
ml_word('ts', algebra_symbol, forms(['ts']), demand([question_corpus(1), supplement_class('algebra_symbol')])).
ml_word('tsunami', noun, forms(['tsunami', 'tsunamis']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('tub', noun, forms(['tub', 'tubs']), demand([dataset(62)])).
ml_word('tub', verb, forms(['tub', 'tubbed', 'tubbing', 'tubs']), demand([dataset(62)])).
ml_word('tuesday', noun, forms(['tuesday', 'tuesdays']), demand([question_corpus(1), dataset(54)])).
ml_word('tuna', noun, forms(['tuna', 'tunas']), demand([dataset(10)])).
ml_word('tune', verb, forms(['tune', 'tuned', 'tunes', 'tuning']), demand([dataset(8)])).
ml_word('tunnel', noun, forms(['tunnel', 'tunnels']), demand([dataset(10)])).
ml_word('tunnel', verb, forms(['tunnel', 'tunneled', 'tunneling', 'tunnels']), demand([dataset(10)])).
ml_word('turn', noun, forms(['turn', 'turns']), demand([question_corpus(1), dataset(63)])).
ml_word('turn', verb, forms(['turn', 'turned', 'turning', 'turns']), demand([question_corpus(2), dataset(91)])).
ml_word('turning', noun, forms(['turning', 'turnings']), demand([question_corpus(1), dataset(2)])).
ml_word('turtle', noun, forms(['turtle', 'turtles']), demand([question_corpus(1), dataset(34)])).
ml_word('tv', abbreviation, forms(['tv']), demand([dataset(19), supplement_class('abbreviation')])).
ml_word('twelfth', noun, forms(['twelfth', 'twelfths']), demand([question_corpus(2)])).
ml_word('twelve', noun, forms(['twelve', 'twelves']), demand([dataset(2)])).
ml_word('twelve', adjective, forms(['twelve']), demand([dataset(2)])).
ml_word('twenty', noun, forms(['twenties', 'twenty']), demand([dataset(15)])).
ml_word('twenty', adjective, forms(['twenty']), demand([dataset(15)])).
ml_word('twice', adverb, forms(['twice']), demand([dataset(427)])).
ml_word('tyler', noun, forms(['tyler', 'tylers']), demand([question_corpus(3)])).
ml_word('type', noun, forms(['type', 'types']), demand([question_corpus(12), dataset(46)])).
ml_word('type', verb, forms(['type', 'typed', 'types', 'typing']), demand([question_corpus(12), dataset(46)])).
ml_word('typical', adjective, forms(['typical']), demand([question_corpus(1)])).
ml_word('typically', adverb, forms(['typically']), demand([dataset(6), supplement_class('adverb')])).
ml_word('tyson', given_name, forms(['tyson']), demand([dataset(12), supplement_class('given_name')])).
ml_word('unable', adjective, forms(['unable']), demand([dataset(9)])).
ml_word('unclear', adjective, forms(['unclear']), demand([question_corpus(6), supplement_class('adjective')])).
ml_word('uncover', verb, forms(['uncover', 'uncovered', 'uncovering', 'uncovers']), demand([dataset(6)])).
ml_word('uncut', adjective, forms(['uncut']), demand([dataset(4)])).
ml_word('under', adjective, forms(['under']), demand([question_corpus(2), dataset(23)])).
ml_word('under', adverb, forms(['under']), demand([question_corpus(2), dataset(23)])).
ml_word('under', preposition, forms(['under']), demand([question_corpus(2), dataset(23)])).
ml_word('undergo', verb, forms(['undergo', 'undergoes', 'undergoing', 'undergone', 'underwent']), demand([dataset(2)])).
ml_word('underneath', adverb, forms(['underneath']), demand([dataset(2)])).
ml_word('underneath', preposition, forms(['underneath']), demand([dataset(2)])).
ml_word('understand', verb, forms(['understand', 'understanded', 'understanding', 'understands', 'understood']), demand([question_corpus(19)])).
ml_word('understanding', noun, forms(['understanding', 'understandings']), demand([question_corpus(12)])).
ml_word('understanding', adjective, forms(['understanding']), demand([question_corpus(11)])).
ml_word('undetected', adjective, forms(['undetected']), demand([dataset(3), supplement_class('adjective')])).
ml_word('undried', adjective, forms(['undried']), demand([dataset(2), supplement_class('adjective')])).
ml_word('unexpected', adjective, forms(['unexpected']), demand([question_corpus(2)])).
ml_word('unfinished', adjective, forms(['unfinished']), demand([question_corpus(2)])).
ml_word('unfit', verb, forms(['unfit', 'unfited', 'unfiting', 'unfits']), demand([dataset(4)])).
ml_word('unfit', adjective, forms(['unfit']), demand([dataset(4)])).
ml_word('unfollow', verb, forms(['unfollow', 'unfollowed', 'unfollowing', 'unfollows']), demand([dataset(4), supplement_class('corpus_verb')])).
ml_word('unfortunately', adverb, forms(['unfortunately']), demand([dataset(4), supplement_class('adverb')])).
ml_word('ungridded', adjective, forms(['ungridded']), demand([question_corpus(1), supplement_class('adjective')])).
ml_word('unicorn', noun, forms(['unicorn', 'unicorns']), demand([dataset(17)])).
ml_word('unicycle', noun, forms(['unicycle', 'unicycles']), demand([dataset(16), supplement_class('common_noun')])).
ml_word('uninterrupted', adjective, forms(['uninterrupted']), demand([dataset(8), supplement_class('adjective')])).
ml_word('unique', noun, forms(['unique', 'uniques']), demand([question_corpus(1)])).
ml_word('unique', adjective, forms(['unique']), demand([question_corpus(1)])).
ml_word('unit', noun, forms(['unit', 'units']), demand([question_corpus(27), dataset(15), questioning_paper_lexicon])).
ml_word('unknown', adjective, forms(['unknown']), demand([question_corpus(7)])).
ml_word('unless', conjunction, forms(['unless']), demand([dataset(4)])).
ml_word('unlike', adjective, forms(['unlike']), demand([question_corpus(2)])).
ml_word('unlikely', adjective, forms(['unlikely']), demand([question_corpus(1)])).
ml_word('unlikely', adverb, forms(['unlikely']), demand([question_corpus(1)])).
ml_word('unnoticed', adjective, forms(['unnoticed']), demand([dataset(2), supplement_class('adjective')])).
ml_word('unoccupied', adjective, forms(['unoccupied']), demand([dataset(4), supplement_class('adjective')])).
ml_word('unproductive', adjective, forms(['unproductive']), demand([question_corpus(1), supplement_class('adjective')])).
ml_word('unreasonable', adjective, forms(['unreasonable']), demand([question_corpus(1)])).
ml_word('unsold', adjective, forms(['unsold']), demand([dataset(18), supplement_class('adjective')])).
ml_word('unsure', adjective, forms(['unsure']), demand([question_corpus(1), supplement_class('adjective')])).
ml_word('until', preposition, forms(['until']), demand([dataset(34)])).
ml_word('until', conjunction, forms(['until']), demand([dataset(34)])).
ml_word('untrained', adjective, forms(['untrained']), demand([dataset(2)])).
ml_word('untrue', adjective, forms(['untrue']), demand([question_corpus(1)])).
ml_word('untrue', adverb, forms(['untrue']), demand([question_corpus(1)])).
ml_word('unused', adjective, forms(['unused']), demand([dataset(1)])).
ml_word('up', noun, forms(['up', 'ups']), demand([question_corpus(17), dataset(476)])).
ml_word('up', adjective, forms(['up']), demand([question_corpus(17), dataset(445)])).
ml_word('up', adverb, forms(['up']), demand([question_corpus(17), dataset(445)])).
ml_word('up', preposition, forms(['up']), demand([question_corpus(17), dataset(445)])).
ml_word('upcoming', adjective, forms(['upcoming']), demand([question_corpus(1), dataset(6), supplement_class('adjective')])).
ml_word('update', noun, forms(['update', 'updates']), demand([dataset(15), supplement_class('common_noun')])).
ml_word('update', verb, forms(['update', 'updated', 'updates', 'updating']), demand([dataset(15), supplement_class('corpus_verb')])).
ml_word('upon', preposition, forms(['upon']), demand([question_corpus(2)])).
ml_word('upset', noun, forms(['upset', 'upsets']), demand([dataset(4)])).
ml_word('upset', verb, forms(['upset', 'upsets', 'upsetting']), demand([dataset(4)])).
ml_word('upset', adjective, forms(['upset']), demand([dataset(4)])).
ml_word('ursula', noun, forms(['ursula', 'ursulas']), demand([dataset(6)])).
ml_word('use', noun, forms(['use', 'uses']), demand([question_corpus(98), dataset(252)])).
ml_word('use', verb, forms(['use', 'used', 'uses', 'using']), demand([question_corpus(141), dataset(428)])).
ml_word('useful', adjective, forms(['useful']), demand([question_corpus(4)])).
ml_word('usual', adjective, forms(['usual']), demand([dataset(4)])).
ml_word('usually', adverb, forms(['usually']), demand([dataset(6), supplement_class('adverb')])).
ml_word('utility', noun, forms(['utilities', 'utility']), demand([dataset(7)])).
ml_word('vacation', noun, forms(['vacation', 'vacations']), demand([dataset(10)])).
ml_word('vaccine', adjective, forms(['vaccine']), demand([dataset(7)])).
ml_word('vacuum', noun, forms(['vacua', 'vacuum', 'vacuums']), demand([dataset(72)])).
ml_word('valid', adjective, forms(['valid']), demand([question_corpus(1), dataset(16)])).
ml_word('value', noun, forms(['value', 'values']), demand([question_corpus(143), dataset(116), questioning_paper_lexicon])).
ml_word('value', verb, forms(['value', 'valued', 'values', 'valuing']), demand([question_corpus(143), dataset(116), questioning_paper_lexicon])).
ml_word('vampire', noun, forms(['vampire', 'vampires']), demand([dataset(69)])).
ml_word('vanilla', noun, forms(['vanilla', 'vanillas']), demand([dataset(4)])).
ml_word('variable', noun, forms(['variable', 'variables']), demand([question_corpus(5), dataset(5), questioning_paper_lexicon])).
ml_word('variable', adjective, forms(['variable']), demand([question_corpus(2), dataset(2), questioning_paper_lexicon])).
ml_word('various', adjective, forms(['various']), demand([dataset(12)])).
ml_word('varsity', noun, forms(['varsities', 'varsity']), demand([dataset(4)])).
ml_word('vegetable', noun, forms(['vegetable', 'vegetables']), demand([question_corpus(2), dataset(32), supplement_class('common_noun')])).
ml_word('vehicle', noun, forms(['vehicle', 'vehicles']), demand([dataset(14)])).
ml_word('velvet', noun, forms(['velvet', 'velvets']), demand([dataset(14)])).
ml_word('velvet', verb, forms(['velvet', 'velveted', 'velveting', 'velvets']), demand([dataset(14)])).
ml_word('velvet', adjective, forms(['velvet']), demand([dataset(14)])).
ml_word('vend', verb, forms(['vend', 'vended', 'vending', 'vends']), demand([dataset(13)])).
ml_word('venue', noun, forms(['venue', 'venues']), demand([dataset(8)])).
ml_word('verify', verb, forms(['verified', 'verifies', 'verify', 'verifying']), demand([question_corpus(1)])).
ml_word('verse', noun, forms(['verse', 'verses']), demand([dataset(14)])).
ml_word('verse', verb, forms(['verse', 'versed', 'verses', 'versing']), demand([dataset(14)])).
ml_word('version', noun, forms(['version', 'versions']), demand([question_corpus(1), dataset(2)])).
ml_word('versus', preposition, forms(['versus']), demand([question_corpus(1)])).
ml_word('vertex', noun, forms(['vertex', 'vertexes', 'vertices']), demand([question_corpus(2), questioning_paper_lexicon])).
ml_word('vertical', noun, forms(['vertical', 'verticals']), demand([question_corpus(1), dataset(19)])).
ml_word('vertical', adjective, forms(['vertical']), demand([question_corpus(1), dataset(19)])).
ml_word('vertically', adverb, forms(['vertically']), demand([dataset(4)])).
ml_word('very', adjective, forms(['verier', 'veriest', 'very']), demand([dataset(16)])).
ml_word('very', adverb, forms(['very']), demand([dataset(16)])).
ml_word('vest', noun, forms(['vest', 'vests']), demand([dataset(15)])).
ml_word('vest', verb, forms(['vest', 'vested', 'vesting', 'vests']), demand([dataset(15)])).
ml_word('vet', noun, forms(['vet', 'vets']), demand([dataset(3), supplement_class('common_noun')])).
ml_word('video', noun, forms(['video', 'videos']), demand([question_corpus(1), dataset(109), supplement_class('common_noun')])).
ml_word('view', noun, forms(['view', 'views']), demand([question_corpus(1), dataset(2)])).
ml_word('view', verb, forms(['view', 'viewed', 'viewing', 'views']), demand([question_corpus(1), dataset(10)])).
ml_word('viewer', noun, forms(['viewer', 'viewers']), demand([dataset(7)])).
ml_word('village', noun, forms(['village', 'villages']), demand([dataset(10), supplement_class('common_noun')])).
ml_word('violence', noun, forms(['violence', 'violences']), demand([dataset(12)])).
ml_word('violence', verb, forms(['violence', 'violenced', 'violences', 'violencing']), demand([dataset(12)])).
ml_word('virus', noun, forms(['virus', 'viruses']), demand([dataset(10)])).
ml_word('visible', adjective, forms(['visible']), demand([question_corpus(2)])).
ml_word('visit', noun, forms(['visit', 'visits']), demand([dataset(31)])).
ml_word('visit', verb, forms(['visit', 'visited', 'visiting', 'visits']), demand([dataset(46)])).
ml_word('visitor', noun, forms(['visitor', 'visitors']), demand([dataset(54), supplement_class('common_noun')])).
ml_word('vlogger', noun, forms(['vlogger', 'vloggers']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('vocabulary', noun, forms(['vocabularies', 'vocabulary']), demand([question_corpus(1)])).
ml_word('voice', noun, forms(['voice', 'voices']), demand([question_corpus(1)])).
ml_word('voice', verb, forms(['voice', 'voiced', 'voices', 'voicing']), demand([question_corpus(1)])).
ml_word('volleyball', noun, forms(['volleyball', 'volleyballs']), demand([dataset(12), supplement_class('common_noun')])).
ml_word('voltaire', given_name, forms(['voltaire']), demand([dataset(6), supplement_class('given_name')])).
ml_word('volume', noun, forms(['volume', 'volumes']), demand([question_corpus(17), dataset(14), questioning_paper_lexicon])).
ml_word('volunteer', noun, forms(['volunteer', 'volunteers']), demand([question_corpus(1)])).
ml_word('volunteer', verb, forms(['volunteer', 'volunteered', 'volunteering', 'volunteers']), demand([question_corpus(1)])).
ml_word('volunteer', adjective, forms(['volunteer']), demand([question_corpus(1)])).
ml_word('vote', noun, forms(['vote', 'votes']), demand([question_corpus(4), dataset(27)])).
ml_word('vote', verb, forms(['vote', 'voted', 'votes', 'voting']), demand([question_corpus(8), dataset(27)])).
ml_word('w', algebra_symbol, forms(['w']), demand([dataset(7), supplement_class('algebra_symbol')])).
ml_word('waffle', noun, forms(['waffle', 'waffles']), demand([question_corpus(1), dataset(6)])).
ml_word('wage', noun, forms(['wage', 'wages']), demand([dataset(22)])).
ml_word('wage', verb, forms(['wage', 'waged', 'wages', 'waging']), demand([dataset(22)])).
ml_word('wages', noun, forms(['wages', 'wageses']), demand([dataset(14)])).
ml_word('wagon', noun, forms(['wagon', 'wagons']), demand([question_corpus(3)])).
ml_word('wagon', verb, forms(['wagon', 'wagoned', 'wagoning', 'wagons']), demand([question_corpus(3)])).
ml_word('wait', noun, forms(['wait', 'waits']), demand([dataset(31)])).
ml_word('wait', verb, forms(['wait', 'waited', 'waiting', 'waits']), demand([dataset(33)])).
ml_word('waiter', noun, forms(['waiter', 'waiters']), demand([dataset(2)])).
ml_word('wake', verb, forms(['wake', 'waked', 'wakes', 'waking', 'woke', 'woken']), demand([dataset(4), supplement_class('corpus_verb')])).
ml_word('walk', noun, forms(['walk', 'walks']), demand([question_corpus(3), dataset(181)])).
ml_word('walk', verb, forms(['walk', 'walked', 'walking', 'walks']), demand([question_corpus(4), dataset(240)])).
ml_word('wall', noun, forms(['wall', 'walls']), demand([dataset(43)])).
ml_word('walled', adjective, forms(['walled']), demand([dataset(12), supplement_class('adjective')])).
ml_word('wallet', noun, forms(['wallet', 'wallets']), demand([dataset(8)])).
ml_word('wallpaper', noun, forms(['wallpaper']), demand([dataset(24), supplement_class('common_noun')])).
ml_word('walmart', named_entity, forms(['walmart']), demand([dataset(12), supplement_class('named_entity')])).
ml_word('wanda', given_name, forms(['wanda']), demand([dataset(12), supplement_class('given_name')])).
ml_word('want', verb, forms(['want', 'wanted', 'wanting', 'wants']), demand([question_corpus(14), dataset(379)])).
ml_word('war', noun, forms(['war', 'wars']), demand([dataset(22)])).
ml_word('war', verb, forms(['war', 'wared', 'waring', 'warred', 'warring', 'wars']), demand([dataset(22)])).
ml_word('warehouse', noun, forms(['warehouse', 'warehouses']), demand([dataset(2)])).
ml_word('warehouse', verb, forms(['warehouse', 'warehoused', 'warehouses', 'warehousing']), demand([dataset(2)])).
ml_word('warm', noun, forms(['warm', 'warms']), demand([question_corpus(1)])).
ml_word('warm', verb, forms(['warm', 'warmed', 'warming', 'warms']), demand([question_corpus(1)])).
ml_word('warm', adjective, forms(['warm', 'warmer', 'warmest']), demand([question_corpus(1)])).
ml_word('wash', noun, forms(['wash', 'washes']), demand([question_corpus(1), dataset(44)])).
ml_word('wash', verb, forms(['wash', 'washed', 'washes', 'washing']), demand([question_corpus(1), dataset(95)])).
ml_word('wash', adjective, forms(['wash']), demand([question_corpus(1), dataset(28)])).
ml_word('washed', adjective, forms(['washed']), demand([dataset(17)])).
ml_word('washing', noun, forms(['washing', 'washings']), demand([dataset(34)])).
ml_word('watch', noun, forms(['watch', 'watches']), demand([dataset(79)])).
ml_word('watch', verb, forms(['watch', 'watched', 'watches', 'watching']), demand([dataset(123)])).
ml_word('watches', noun, forms(['watches']), demand([dataset(37)])).
ml_word('water', noun, forms(['water', 'waters']), demand([question_corpus(10), dataset(302)])).
ml_word('water', verb, forms(['water', 'watered', 'watering', 'waters']), demand([question_corpus(10), dataset(302)])).
ml_word('watermelon', noun, forms(['watermelon', 'watermelons']), demand([dataset(56)])).
ml_word('wave', noun, forms(['wave', 'waves']), demand([dataset(4)])).
ml_word('wave', verb, forms(['wave', 'waved', 'waves', 'waving']), demand([dataset(4)])).
ml_word('wax', verb, forms(['wax', 'waxed', 'waxes', 'waxing']), demand([dataset(6)])).
ml_word('way', noun, forms(['way', 'ways']), demand([question_corpus(204), dataset(55)])).
ml_word('way', verb, forms(['way', 'wayed', 'waying', 'ways']), demand([question_corpus(204), dataset(55)])).
ml_word('way', adverb, forms(['way']), demand([question_corpus(166), dataset(52)])).
ml_word('wayne', place_name, forms(['wayne']), demand([question_corpus(1), supplement_class('place_name')])).
ml_word('weapon', noun, forms(['weapon', 'weapons']), demand([dataset(7)])).
ml_word('wear', noun, forms(['wear', 'wears']), demand([dataset(22)])).
ml_word('wear', verb, forms(['wear', 'weared', 'wearing', 'wears', 'wore', 'worn']), demand([dataset(77), supplement_class('corpus_verb')])).
ml_word('wearing', noun, forms(['wearing', 'wearings']), demand([dataset(55)])).
ml_word('wearing', adjective, forms(['wearing']), demand([dataset(55)])).
ml_word('website', noun, forms(['website', 'websites']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('wed', verb, forms(['wed', 'wedded', 'wedding', 'weded', 'weding', 'weds']), demand([dataset(22)])).
ml_word('wedding', noun, forms(['wedding', 'weddings']), demand([dataset(22)])).
ml_word('wednesday', noun, forms(['wednesday', 'wednesdays']), demand([dataset(70), supplement_class('temporal_word')])).
ml_word('weed', noun, forms(['weed', 'weeds']), demand([dataset(12)])).
ml_word('weed', verb, forms(['weed', 'weeded', 'weeding', 'weeds']), demand([dataset(12)])).
ml_word('week', noun, forms(['week', 'weeks']), demand([question_corpus(1), dataset(953)])).
ml_word('weekday', noun, forms(['weekday', 'weekdays']), demand([dataset(53), supplement_class('temporal_word')])).
ml_word('weekend', noun, forms(['weekend', 'weekends']), demand([question_corpus(1), dataset(76), supplement_class('temporal_word')])).
ml_word('weekly', noun, forms(['weeklies', 'weekly']), demand([dataset(19)])).
ml_word('weekly', adjective, forms(['weekly']), demand([dataset(19)])).
ml_word('weekly', adverb, forms(['weekly']), demand([dataset(19)])).
ml_word('weeknight', noun, forms(['weeknight', 'weeknights']), demand([dataset(4), supplement_class('temporal_word')])).
ml_word('weigh', noun, forms(['naut', 'weigh', 'weighs']), demand([question_corpus(1), dataset(86)])).
ml_word('weigh', verb, forms(['weigh', 'weighed', 'weighing', 'weighs']), demand([question_corpus(2), dataset(100)])).
ml_word('weight', noun, forms(['weight', 'weights']), demand([question_corpus(9), dataset(215)])).
ml_word('weight', verb, forms(['weight', 'weighted', 'weighting', 'weights']), demand([question_corpus(9), dataset(215)])).
ml_word('well', noun, forms(['well', 'wells']), demand([question_corpus(7), dataset(29)])).
ml_word('well', verb, forms(['well', 'welled', 'welling', 'wells']), demand([question_corpus(7), dataset(29)])).
ml_word('well', adjective, forms(['best', 'better', 'well']), demand([question_corpus(24), dataset(49)])).
ml_word('well', adverb, forms(['well']), demand([question_corpus(7), dataset(29)])).
ml_word('wendi', given_name, forms(['wendi']), demand([dataset(40), supplement_class('given_name')])).
ml_word('wendy', given_name, forms(['wendy']), demand([dataset(20), supplement_class('given_name')])).
ml_word('went', noun, forms(['went', 'wents']), demand([question_corpus(5), dataset(124)])).
ml_word('wes', given_name, forms(['wes']), demand([dataset(3), supplement_class('given_name')])).
ml_word('west', noun, forms(['west', 'wests']), demand([dataset(4)])).
ml_word('west', verb, forms(['west', 'wested', 'westing', 'wests']), demand([dataset(4)])).
ml_word('west', adjective, forms(['west']), demand([dataset(4)])).
ml_word('west', adverb, forms(['west']), demand([dataset(4)])).
ml_word('wet', noun, forms(['wet', 'wets']), demand([dataset(45)])).
ml_word('wet', verb, forms(['wet', 'wets', 'wetting']), demand([dataset(45)])).
ml_word('wet', adjective, forms(['wet', 'wetter', 'wettest']), demand([dataset(45)])).
ml_word('whatever', pronoun, forms(['whatever']), demand([dataset(8)])).
ml_word('wheel', noun, forms(['wheel', 'wheels']), demand([question_corpus(3), dataset(40)])).
ml_word('wheel', verb, forms(['wheel', 'wheeled', 'wheeling', 'wheels']), demand([question_corpus(3), dataset(40)])).
ml_word('where', noun, forms(['where', 'wheres']), demand([question_corpus(39), dataset(67)])).
ml_word('where', adverb, forms(['where']), demand([question_corpus(39), dataset(67)])).
ml_word('where', conjunction, forms(['where']), demand([question_corpus(39), dataset(67)])).
ml_word('whether', pronoun, forms(['whether']), demand([question_corpus(10), dataset(8)])).
ml_word('whether', conjunction, forms(['whether']), demand([question_corpus(10), dataset(8)])).
ml_word('while', noun, forms(['while', 'whiles']), demand([question_corpus(2), dataset(125)])).
ml_word('while', verb, forms(['while', 'whiled', 'whiles', 'whiling']), demand([question_corpus(2), dataset(125)])).
ml_word('while', preposition, forms(['while']), demand([question_corpus(2), dataset(125)])).
ml_word('while', conjunction, forms(['while']), demand([question_corpus(2), dataset(125)])).
ml_word('white', noun, forms(['white', 'whites']), demand([dataset(87)])).
ml_word('white', verb, forms(['white', 'whited', 'whites', 'whiting']), demand([dataset(87)])).
ml_word('white', adjective, forms(['white', 'whiter', 'whitest']), demand([dataset(87)])).
ml_word('whoever', pronoun, forms(['whoever']), demand([dataset(4)])).
ml_word('whole', noun, forms(['whole', 'wholes']), demand([question_corpus(11), dataset(122)])).
ml_word('whole', adjective, forms(['whole']), demand([question_corpus(11), dataset(122)])).
ml_word('whose', pronoun, forms(['whose']), demand([question_corpus(1)])).
ml_word('wick', noun, forms(['wick', 'wicks']), demand([dataset(9)])).
ml_word('wick', verb, forms(['wick', 'wicked', 'wicking', 'wicks']), demand([dataset(9)])).
ml_word('wide', noun, forms(['wide', 'wides']), demand([question_corpus(3), dataset(15)])).
ml_word('wide', adjective, forms(['wide', 'wider', 'widest']), demand([question_corpus(4), dataset(15)])).
ml_word('wide', adverb, forms(['wide']), demand([question_corpus(3), dataset(15)])).
ml_word('widget', noun, forms(['widget', 'widgets']), demand([dataset(10), supplement_class('common_noun')])).
ml_word('width', noun, forms(['width', 'widths']), demand([question_corpus(6), dataset(48)])).
ml_word('wife', noun, forms(['wife', 'wives']), demand([dataset(45)])).
ml_word('wilderness', noun, forms(['wilderness', 'wildernesses']), demand([dataset(2)])).
ml_word('will', verb, forms(['will', 'willed', 'willing', 'wills']), demand([dataset(6)])).
ml_word('william', given_name, forms(['william']), demand([dataset(24), supplement_class('given_name')])).
ml_word('willing', adjective, forms(['willing']), demand([dataset(6)])).
ml_word('willowton', place_name, forms(['willowton']), demand([dataset(4), supplement_class('place_name')])).
ml_word('wilson', given_name, forms(['wilson']), demand([dataset(4), supplement_class('given_name')])).
ml_word('win', verb, forms(['win', 'wined', 'wining', 'winning', 'wins', 'won']), demand([question_corpus(3), dataset(107)])).
ml_word('wind', verb, forms(['wind', 'winded', 'winding', 'winds', 'wound']), demand([dataset(2)])).
ml_word('winding', noun, forms(['winding', 'windings']), demand([dataset(2)])).
ml_word('winding', adjective, forms(['winding']), demand([dataset(2)])).
ml_word('window', noun, forms(['window', 'windows']), demand([question_corpus(2), dataset(83)])).
ml_word('window', verb, forms(['window', 'windowed', 'windowing', 'windows']), demand([question_corpus(2), dataset(83)])).
ml_word('wine', noun, forms(['wine', 'wines']), demand([dataset(23)])).
ml_word('winning', noun, forms(['winning', 'winnings']), demand([question_corpus(1), dataset(5)])).
ml_word('winning', adjective, forms(['winning']), demand([question_corpus(1), dataset(5)])).
ml_word('winston', given_name, forms(['winston']), demand([dataset(9), supplement_class('given_name')])).
ml_word('winter', noun, forms(['winter', 'winters']), demand([question_corpus(1), dataset(6)])).
ml_word('winter', verb, forms(['winter', 'wintered', 'wintering', 'winters']), demand([question_corpus(1), dataset(6)])).
ml_word('wish', noun, forms(['wish', 'wishes']), demand([question_corpus(2), dataset(4)])).
ml_word('wish', verb, forms(['wish', 'wished', 'wishes', 'wishing']), demand([question_corpus(2), dataset(4)])).
ml_word('within', adverb, forms(['within']), demand([question_corpus(4), dataset(8)])).
ml_word('within', preposition, forms(['within']), demand([question_corpus(4), dataset(8)])).
ml_word('without', adverb, forms(['without']), demand([question_corpus(34), dataset(24)])).
ml_word('without', preposition, forms(['without']), demand([question_corpus(34), dataset(24)])).
ml_word('without', conjunction, forms(['without']), demand([question_corpus(34), dataset(24)])).
ml_word('woman', noun, forms(['woman', 'women']), demand([dataset(65)])).
ml_word('woman', verb, forms(['woman', 'womaned', 'womaning', 'womans']), demand([dataset(5)])).
ml_word('won', noun, forms(['won', 'wons']), demand([dataset(44)])).
ml_word('won', verb, forms(['won', 'woned', 'woning', 'wons']), demand([dataset(44)])).
ml_word('wonder', noun, forms(['wonder', 'wonders']), demand([question_corpus(2), dataset(12)])).
ml_word('wonder', verb, forms(['wonder', 'wondered', 'wondering', 'wonders']), demand([question_corpus(56), dataset(14)])).
ml_word('wonder', adjective, forms(['wonder']), demand([question_corpus(2)])).
ml_word('wonder', adverb, forms(['wonder']), demand([question_corpus(2)])).
ml_word('wonders', adverb, forms(['wonders']), demand([dataset(12)])).
ml_word('wood', noun, forms(['wood', 'woods']), demand([dataset(18)])).
ml_word('wood', verb, forms(['wood', 'wooded', 'wooding', 'woods']), demand([dataset(18)])).
ml_word('wood', adjective, forms(['wood']), demand([dataset(18)])).
ml_word('word', noun, forms(['word', 'words']), demand([question_corpus(28), dataset(38)])).
ml_word('word', verb, forms(['word', 'worded', 'wording', 'words']), demand([question_corpus(28), dataset(38)])).
ml_word('work', noun, forms(['work', 'works']), demand([question_corpus(37), dataset(161)])).
ml_word('work', verb, forms(['work', 'worked', 'working', 'works']), demand([question_corpus(47), dataset(275)])).
ml_word('workday', noun, forms(['workday', 'workdays']), demand([dataset(3)])).
ml_word('workday', adjective, forms(['workday']), demand([dataset(3)])).
ml_word('worker', noun, forms(['worker', 'workers']), demand([dataset(46)])).
ml_word('workout', noun, forms(['workout', 'workouts']), demand([dataset(6), supplement_class('common_noun')])).
ml_word('world', noun, forms(['world', 'worlds']), demand([question_corpus(5), dataset(2)])).
ml_word('worm', verb, forms(['worm', 'wormed', 'worming', 'worms']), demand([dataset(8)])).
ml_word('worry', noun, forms(['worries', 'worry']), demand([question_corpus(1)])).
ml_word('worry', verb, forms(['worried', 'worries', 'worry', 'worrying']), demand([question_corpus(1)])).
ml_word('worth', noun, forms(['worth', 'worths']), demand([dataset(108)])).
ml_word('worth', verb, forms(['worth', 'worthed', 'worthing', 'worths']), demand([dataset(108)])).
ml_word('worth', adjective, forms(['worth']), demand([dataset(108)])).
ml_word('wrap', noun, forms(['wrap', 'wraps']), demand([dataset(18)])).
ml_word('wrap', verb, forms(['wrap', 'wraped', 'wraping', 'wrapped', 'wrapping', 'wraps']), demand([dataset(25)])).
ml_word('wrist', noun, forms(['wrist', 'wrists']), demand([dataset(16)])).
ml_word('write', verb, forms(['write', 'writes', 'writing', 'written', 'wrote']), demand([question_corpus(34), dataset(28)])).
ml_word('writer', noun, forms(['writer', 'writers']), demand([question_corpus(4)])).
ml_word('writing', noun, forms(['writing', 'writings']), demand([question_corpus(3), dataset(3)])).
ml_word('wrong', noun, forms(['wrong', 'wrongs']), demand([question_corpus(1)])).
ml_word('wrong', verb, forms(['wrong', 'wronged', 'wronging', 'wrongs']), demand([question_corpus(1)])).
ml_word('wrong', adjective, forms(['wrong']), demand([question_corpus(1)])).
ml_word('wrong', adverb, forms(['wrong']), demand([question_corpus(1)])).
ml_word('wrote', verb, forms(['wrote', 'wroted', 'wrotes', 'wroting']), demand([question_corpus(3), dataset(1)])).
ml_word('x', algebra_symbol, forms(['x']), demand([question_corpus(1), dataset(2698), supplement_class('algebra_symbol')])).
ml_word('xavier', given_name, forms(['xavier']), demand([dataset(20), supplement_class('given_name')])).
ml_word('xena', given_name, forms(['xena']), demand([dataset(14), supplement_class('given_name')])).
ml_word('xl', abbreviation, forms(['xl']), demand([dataset(9), supplement_class('abbreviation')])).
ml_word('y', noun, forms(['y', 'y''s']), demand([question_corpus(1), dataset(8)])).
ml_word('y', pronoun, forms(['y']), demand([question_corpus(1), dataset(8)])).
ml_word('yard', noun, forms(['yard', 'yards']), demand([question_corpus(1), dataset(47)])).
ml_word('yard', verb, forms(['yard', 'yarded', 'yarding', 'yards']), demand([question_corpus(1), dataset(47)])).
ml_word('yardstick', noun, forms(['yardstick', 'yardsticks']), demand([question_corpus(1)])).
ml_word('yarn', noun, forms(['yarn', 'yarns']), demand([dataset(10)])).
ml_word('yd', unit_abbreviation, forms(['yd']), demand([dataset(5), supplement_class('unit_abbreviation')])).
ml_word('year', noun, forms(['year', 'years']), demand([question_corpus(6), dataset(971)])).
ml_word('yell', verb, forms(['yell', 'yelled', 'yelling', 'yells']), demand([dataset(5)])).
ml_word('yellow', noun, forms(['yellow', 'yellows']), demand([question_corpus(3), dataset(35)])).
ml_word('yellow', verb, forms(['yellow', 'yellowed', 'yellowing', 'yellows']), demand([question_corpus(3), dataset(35)])).
ml_word('yellow', adjective, forms(['yellow', 'yellower', 'yellowest']), demand([question_corpus(3), dataset(35)])).
ml_word('yen', noun, forms(['yen', 'yens']), demand([dataset(17)])).
ml_word('yes', adverb, forms(['yes']), demand([question_corpus(4)])).
ml_word('yesterday', noun, forms(['yesterday', 'yesterdays']), demand([question_corpus(2), dataset(16)])).
ml_word('yesterday', adverb, forms(['yesterday']), demand([question_corpus(2), dataset(16)])).
ml_word('yet', noun, forms(['yet', 'yets']), demand([question_corpus(2)])).
ml_word('yet', adverb, forms(['yet']), demand([question_corpus(2)])).
ml_word('yet', conjunction, forms(['yet']), demand([question_corpus(2)])).
ml_word('yield', noun, forms(['yield', 'yields']), demand([dataset(12)])).
ml_word('yield', verb, forms(['yield', 'yielded', 'yielding', 'yields']), demand([dataset(14)])).
ml_word('yielding', adjective, forms(['yielding']), demand([dataset(2)])).
ml_word('yolk', noun, forms(['yolk', 'yolks']), demand([dataset(32)])).
ml_word('york', place_name, forms(['york']), demand([dataset(2), supplement_class('place_name')])).
ml_word('young', noun, forms(['young', 'youngs']), demand([question_corpus(2), dataset(9)])).
ml_word('young', adjective, forms(['young', 'younger', 'youngest']), demand([question_corpus(2), dataset(24)])).
ml_word('yours', pronoun, forms(['yours']), demand([question_corpus(1)])).
ml_word('yourself', pronoun, forms(['yourself']), demand([question_corpus(1)])).
ml_word('yulia', given_name, forms(['yulia']), demand([dataset(10), supplement_class('given_name')])).
ml_word('zander', noun, forms(['zander', 'zanders']), demand([dataset(6)])).
ml_word('zap', verb, forms(['zap', 'zapped', 'zapping', 'zaps']), demand([dataset(10), supplement_class('corpus_verb')])).
ml_word('zero', noun, forms(['zero', 'zeroes', 'zeros']), demand([question_corpus(4), supplement_class('math_term')])).
ml_word('zika', named_entity, forms(['zika']), demand([dataset(6), supplement_class('named_entity')])).
ml_word('zion', noun, forms(['zion', 'zions']), demand([dataset(8)])).
ml_word('zomby', noun, forms(['zombies', 'zomby']), demand([dataset(22), supplement_class('common_noun')])).
ml_word('zone', noun, forms(['zone', 'zones']), demand([dataset(1)])).
ml_word('zone', verb, forms(['zone', 'zoned', 'zones', 'zoning']), demand([dataset(1)])).
ml_word('zoo', noun, forms(['zoo', 'zoos']), demand([dataset(2), supplement_class('common_noun')])).
ml_word('zubir', given_name, forms(['zubir']), demand([dataset(4), supplement_class('given_name')])).
ml_word('zucchini', noun, forms(['zucchini', 'zucchinis']), demand([dataset(8), supplement_class('common_noun')])).
ml_word('π', algebra_symbol, forms(['π']), demand([dataset(2), supplement_class('algebra_symbol')])).
ml_word('πr', algebra_symbol, forms(['πr']), demand([dataset(5), supplement_class('algebra_symbol')])).

% Tokens absent from Webster, counted across admitted demand sources.
ml_unknown('didn', 14).
ml_unknown('doesn', 22).
ml_unknown('hadn', 1).
ml_unknown('ll', 13).
ml_unknown('minis', 2).
ml_unknown('nd', 22).
ml_unknown('rd', 20).
ml_unknown('rds', 2).
ml_unknown('re', 28).
ml_unknown('st', 16).
ml_unknown('starshaped', 1).
ml_unknown('th', 47).
ml_unknown('thiswarmup', 1).
ml_unknown('threedimensional', 1).
ml_unknown('twodigit', 1).
ml_unknown('ve', 11).
ml_unknown('was30', 2).
ml_unknown('wasn', 9).
ml_unknown('weren', 1).

% Slice-1 Webster-only unknowns checked against the authored supplement.
ml_baseline_unknown('ad', 12).
ml_baseline_unknown('addend', 3).
ml_baseline_unknown('addends', 1).
ml_baseline_unknown('ads', 6).
ml_baseline_unknown('agnes', 15).
ml_baseline_unknown('aimee', 4).
ml_baseline_unknown('airline', 8).
ml_baseline_unknown('airplane', 32).
ml_baseline_unknown('airplanes', 4).
ml_baseline_unknown('airport', 3).
ml_baseline_unknown('airtight', 4).
ml_baseline_unknown('alaskan', 2).
ml_baseline_unknown('alex', 21).
ml_baseline_unknown('alice', 8).
ml_baseline_unknown('alisha', 7).
ml_baseline_unknown('allergic', 4).
ml_baseline_unknown('amalie', 18).
ml_baseline_unknown('amanda', 11).
ml_baseline_unknown('amaya', 24).
ml_baseline_unknown('america', 34).
ml_baseline_unknown('amoura', 10).
ml_baseline_unknown('andre', 8).
ml_baseline_unknown('andrew', 17).
ml_baseline_unknown('andy', 24).
ml_baseline_unknown('annie', 10).
ml_baseline_unknown('antonio', 18).
ml_baseline_unknown('anya', 12).
ml_baseline_unknown('arabella', 15).
ml_baseline_unknown('archie', 3).
ml_baseline_unknown('aren', 3).
ml_baseline_unknown('artemis', 9).
ml_baseline_unknown('artworks', 12).
ml_baseline_unknown('arvin', 5).
ml_baseline_unknown('ashley', 14).
ml_baseline_unknown('aubree', 3).
ml_baseline_unknown('avianna', 14).
ml_baseline_unknown('aziz', 22).
ml_baseline_unknown('b', 59).
ml_baseline_unknown('babysit', 4).
ml_baseline_unknown('babysitters', 2).
ml_baseline_unknown('babysitting', 3).
ml_baseline_unknown('backyard', 11).
ml_baseline_unknown('backyards', 4).
ml_baseline_unknown('bali', 8).
ml_baseline_unknown('barney', 8).
ml_baseline_unknown('basketball', 15).
ml_baseline_unknown('basketballs', 12).
ml_baseline_unknown('bathroom', 6).
ml_baseline_unknown('bathrooms', 2).
ml_baseline_unknown('bathtub', 12).
ml_baseline_unknown('bathwater', 4).
ml_baseline_unknown('beckett', 6).
ml_baseline_unknown('becky', 4).
ml_baseline_unknown('bella', 4).
ml_baseline_unknown('bert', 18).
ml_baseline_unknown('beth', 12).
ml_baseline_unknown('billie', 10).
ml_baseline_unknown('birdhouse', 27).
ml_baseline_unknown('birdhouses', 10).
ml_baseline_unknown('blake', 12).
ml_baseline_unknown('boisjoli', 3).
ml_baseline_unknown('boyfriend', 8).
ml_baseline_unknown('brandon', 5).
ml_baseline_unknown('brian', 36).
ml_baseline_unknown('brianna', 8).
ml_baseline_unknown('brie', 6).
ml_baseline_unknown('brinley', 27).
ml_baseline_unknown('bronner', 7).
ml_baseline_unknown('bryan', 8).
ml_baseline_unknown('bubba', 2).
ml_baseline_unknown('budgeted', 10).
ml_baseline_unknown('budgeting', 8).
ml_baseline_unknown('c', 49).
ml_baseline_unknown('c2', 1).
ml_baseline_unknown('cafe', 2).
ml_baseline_unknown('cameron', 10).
ml_baseline_unknown('camille', 4).
ml_baseline_unknown('candice', 21).
ml_baseline_unknown('cannot', 21).
ml_baseline_unknown('cappuccino', 3).
ml_baseline_unknown('carla', 53).
ml_baseline_unknown('carlos', 6).
ml_baseline_unknown('carly', 8).
ml_baseline_unknown('carmela', 4).
ml_baseline_unknown('carolyn', 4).
ml_baseline_unknown('carsharing', 4).
ml_baseline_unknown('cary', 24).
ml_baseline_unknown('catherine', 4).
ml_baseline_unknown('cathy', 24).
ml_baseline_unknown('cauldron', 3).
ml_baseline_unknown('cds', 24).
ml_baseline_unknown('cecil', 10).
ml_baseline_unknown('celine', 8).
ml_baseline_unknown('charles', 3).
ml_baseline_unknown('cheaper', 21).
ml_baseline_unknown('cheesecakes', 20).
ml_baseline_unknown('chester', 6).
ml_baseline_unknown('chloe', 20).
ml_baseline_unknown('choi', 8).
ml_baseline_unknown('chris', 26).
ml_baseline_unknown('christina', 7).
ml_baseline_unknown('cindy', 5).
ml_baseline_unknown('cities', 2).
ml_baseline_unknown('classroom', 31).
ml_baseline_unknown('classrooms', 10).
ml_baseline_unknown('clerk', 6).
ml_baseline_unknown('cloudy', 1).
ml_baseline_unknown('cm', 48).
ml_baseline_unknown('coconut', 32).
ml_baseline_unknown('combo', 6).
ml_baseline_unknown('combos', 2).
ml_baseline_unknown('comcast', 3).
ml_baseline_unknown('committed', 2).
ml_baseline_unknown('communal', 2).
ml_baseline_unknown('concentrated', 4).
ml_baseline_unknown('condominium', 4).
ml_baseline_unknown('connie', 22).
ml_baseline_unknown('cookfire', 6).
ml_baseline_unknown('cookout', 16).
ml_baseline_unknown('coordinate', 5).
ml_baseline_unknown('coordinates', 4).
ml_baseline_unknown('corey', 2).
ml_baseline_unknown('coronavirus', 6).
ml_baseline_unknown('correctly', 2).
ml_baseline_unknown('corresponds', 1).
ml_baseline_unknown('cottage', 8).
ml_baseline_unknown('counterexamples', 1).
ml_baseline_unknown('county', 4).
ml_baseline_unknown('coupon', 30).
ml_baseline_unknown('coupons', 1).
ml_baseline_unknown('crackers', 10).
ml_baseline_unknown('crawled', 2).
ml_baseline_unknown('credit', 5).
ml_baseline_unknown('crew', 9).
ml_baseline_unknown('croissant', 5).
ml_baseline_unknown('croissants', 25).
ml_baseline_unknown('crossword', 7).
ml_baseline_unknown('cucumber', 6).
ml_baseline_unknown('cumulative', 1).
ml_baseline_unknown('cupcake', 4).
ml_baseline_unknown('cupcakes', 67).
ml_baseline_unknown('customer', 30).
ml_baseline_unknown('customers', 143).
ml_baseline_unknown('cycles', 12).
ml_baseline_unknown('cylinder', 10).
ml_baseline_unknown('cylinders', 3).
ml_baseline_unknown('cylindrical', 11).
ml_baseline_unknown('cyrus', 8).
ml_baseline_unknown('d', 22).
ml_baseline_unknown('d2', 1).
ml_baseline_unknown('dakota', 19).
ml_baseline_unknown('danai', 11).
ml_baseline_unknown('dani', 8).
ml_baseline_unknown('danielle', 7).
ml_baseline_unknown('danny', 8).
ml_baseline_unknown('dara', 10).
ml_baseline_unknown('david', 24).
ml_baseline_unknown('davis', 12).
ml_baseline_unknown('daycare', 4).
ml_baseline_unknown('deadline', 6).
ml_baseline_unknown('debra', 7).
ml_baseline_unknown('deforestation', 1).
ml_baseline_unknown('delaney', 8).
ml_baseline_unknown('denny', 3).
ml_baseline_unknown('denver', 16).
ml_baseline_unknown('descriptor', 1).
ml_baseline_unknown('deshaun', 4).
ml_baseline_unknown('desktop', 1).
ml_baseline_unknown('devin', 12).
ml_baseline_unknown('diane', 1).
ml_baseline_unknown('dianne', 5).
ml_baseline_unknown('didn', 14).
ml_baseline_unknown('diego', 13).
ml_baseline_unknown('dodgeballs', 4).
ml_baseline_unknown('doesn', 22).
ml_baseline_unknown('donut', 8).
ml_baseline_unknown('donuts', 61).
ml_baseline_unknown('dorothy', 4).
ml_baseline_unknown('download', 80).
ml_baseline_unknown('downloaded', 5).
ml_baseline_unknown('downloading', 10).
ml_baseline_unknown('downpayment', 6).
ml_baseline_unknown('dr', 13).
ml_baseline_unknown('dumbbell', 3).
ml_baseline_unknown('dumbbells', 6).
ml_baseline_unknown('dumpster', 6).
ml_baseline_unknown('e', 1).
ml_baseline_unknown('earbuds', 5).
ml_baseline_unknown('electronics', 6).
ml_baseline_unknown('elena', 7).
ml_baseline_unknown('eliana', 8).
ml_baseline_unknown('elise', 30).
ml_baseline_unknown('ella', 22).
ml_baseline_unknown('elliott', 42).
ml_baseline_unknown('elsa', 6).
ml_baseline_unknown('email', 2).
ml_baseline_unknown('emails', 25).
ml_baseline_unknown('emily', 10).
ml_baseline_unknown('emma', 10).
ml_baseline_unknown('encourage', 5).
ml_baseline_unknown('espresso', 2).
ml_baseline_unknown('etc', 1).
ml_baseline_unknown('ethereum', 3).
ml_baseline_unknown('euro', 4).
ml_baseline_unknown('euros', 6).
ml_baseline_unknown('eva', 4).
ml_baseline_unknown('ever', 3).
ml_baseline_unknown('exam', 12).
ml_baseline_unknown('exams', 2).
ml_baseline_unknown('extracurricular', 5).
ml_baseline_unknown('extracurriculars', 3).
ml_baseline_unknown('fatima', 5).
ml_baseline_unknown('feedback', 1).
ml_baseline_unknown('fernando', 6).
ml_baseline_unknown('flamethrower', 1).
ml_baseline_unknown('frac', 1).
ml_baseline_unknown('francisco', 1).
ml_baseline_unknown('frankie', 4).
ml_baseline_unknown('ft', 54).
ml_baseline_unknown('fundraiser', 4).
ml_baseline_unknown('gavin', 6).
ml_baseline_unknown('gb', 70).
ml_baseline_unknown('gemstones', 26).
ml_baseline_unknown('geoblocks', 1).
ml_baseline_unknown('geoff', 8).
ml_baseline_unknown('geometry', 2).
ml_baseline_unknown('germany', 7).
ml_baseline_unknown('gigabytes', 5).
ml_baseline_unknown('gina', 8).
ml_baseline_unknown('girlfriend', 8).
ml_baseline_unknown('giselle', 12).
ml_baseline_unknown('giuliana', 3).
ml_baseline_unknown('glenn', 6).
ml_baseline_unknown('goodie', 2).
ml_baseline_unknown('gotten', 10).
ml_baseline_unknown('graham', 10).
ml_baseline_unknown('grandchildren', 8).
ml_baseline_unknown('granville', 7).
ml_baseline_unknown('graph', 20).
ml_baseline_unknown('graphed', 1).
ml_baseline_unknown('graphs', 8).
ml_baseline_unknown('grayson', 7).
ml_baseline_unknown('gremlins', 4).
ml_baseline_unknown('guidelines', 2).
ml_baseline_unknown('gumballs', 41).
ml_baseline_unknown('gym', 6).
ml_baseline_unknown('h', 5).
ml_baseline_unknown('hadn', 1).
ml_baseline_unknown('haircut', 9).
ml_baseline_unknown('haircuts', 49).
ml_baseline_unknown('hamburger', 8).
ml_baseline_unknown('hamburgers', 34).
ml_baseline_unknown('hamza', 3).
ml_baseline_unknown('han', 9).
ml_baseline_unknown('hanna', 12).
ml_baseline_unknown('hardcover', 4).
ml_baseline_unknown('harold', 3).
ml_baseline_unknown('hawaii', 3).
ml_baseline_unknown('hawkins', 10).
ml_baseline_unknown('hawksbill', 6).
ml_baseline_unknown('hayden', 7).
ml_baseline_unknown('hayes', 2).
ml_baseline_unknown('headphones', 8).
ml_baseline_unknown('highlight', 2).
ml_baseline_unknown('hiker', 1).
ml_baseline_unknown('hilary', 4).
ml_baseline_unknown('hillary', 8).
ml_baseline_unknown('histogram', 1).
ml_baseline_unknown('histograms', 1).
ml_baseline_unknown('homework', 38).
ml_baseline_unknown('hortense', 12).
ml_baseline_unknown('hotdog', 32).
ml_baseline_unknown('hotdogs', 53).
ml_baseline_unknown('hs', 1).
ml_baseline_unknown('hung', 1).
ml_baseline_unknown('ignatius', 24).
ml_baseline_unknown('inbox', 7).
ml_baseline_unknown('ingrid', 10).
ml_baseline_unknown('input', 1).
ml_baseline_unknown('inputs', 1).
ml_baseline_unknown('instagram', 2).
ml_baseline_unknown('iphone', 4).
ml_baseline_unknown('iqr', 1).
ml_baseline_unknown('italy', 2).
ml_baseline_unknown('ittymangnark', 4).
ml_baseline_unknown('ivan', 17).
ml_baseline_unknown('j', 1).
ml_baseline_unknown('jace', 10).
ml_baseline_unknown('jackson', 23).
ml_baseline_unknown('jaco', 20).
ml_baseline_unknown('jada', 3).
ml_baseline_unknown('jake', 59).
ml_baseline_unknown('jalapeno', 13).
ml_baseline_unknown('jame', 6).
ml_baseline_unknown('james', 125).
ml_baseline_unknown('janet', 6).
ml_baseline_unknown('janice', 14).
ml_baseline_unknown('jason', 21).
ml_baseline_unknown('javier', 6).
ml_baseline_unknown('jeanette', 8).
ml_baseline_unknown('jeff', 21).
ml_baseline_unknown('jeffrey', 7).
ml_baseline_unknown('jen', 12).
ml_baseline_unknown('jenga', 2).
ml_baseline_unknown('jennifer', 8).
ml_baseline_unknown('jerry', 31).
ml_baseline_unknown('jessica', 18).
ml_baseline_unknown('jethro', 20).
ml_baseline_unknown('jim', 44).
ml_baseline_unknown('jina', 11).
ml_baseline_unknown('joanie', 12).
ml_baseline_unknown('joey', 55).
ml_baseline_unknown('johnson', 16).
ml_baseline_unknown('jones', 8).
ml_baseline_unknown('jorge', 3).
ml_baseline_unknown('jose', 7).
ml_baseline_unknown('josh', 63).
ml_baseline_unknown('jr', 1).
ml_baseline_unknown('juan', 20).
ml_baseline_unknown('judah', 5).
ml_baseline_unknown('julia', 114).
ml_baseline_unknown('julie', 18).
ml_baseline_unknown('jumbo', 7).
ml_baseline_unknown('kamil', 5).
ml_baseline_unknown('karan', 30).
ml_baseline_unknown('karina', 24).
ml_baseline_unknown('karts', 35).
ml_baseline_unknown('katrina', 9).
ml_baseline_unknown('kaylee', 4).
ml_baseline_unknown('keenan', 5).
ml_baseline_unknown('kendra', 32).
ml_baseline_unknown('kenny', 20).
ml_baseline_unknown('kerry', 15).
ml_baseline_unknown('keziah', 5).
ml_baseline_unknown('kg', 143).
ml_baseline_unknown('kgs', 12).
ml_baseline_unknown('kiddie', 18).
ml_baseline_unknown('kiki', 8).
ml_baseline_unknown('kilobyte', 5).
ml_baseline_unknown('kilobytes', 12).
ml_baseline_unknown('kingnook', 2).
ml_baseline_unknown('kiran', 4).
ml_baseline_unknown('kiwi', 3).
ml_baseline_unknown('km', 40).
ml_baseline_unknown('kristin', 12).
ml_baseline_unknown('kwh', 1).
ml_baseline_unknown('kyle', 12).
ml_baseline_unknown('l', 26).
ml_baseline_unknown('landscaping', 4).
ml_baseline_unknown('lara', 8).
ml_baseline_unknown('latte', 2).
ml_baseline_unknown('lattes', 5).
ml_baseline_unknown('launderette', 8).
ml_baseline_unknown('lawnmower', 10).
ml_baseline_unknown('lawnmowers', 4).
ml_baseline_unknown('lb', 7).
ml_baseline_unknown('lbs', 10).
ml_baseline_unknown('leah', 8).
ml_baseline_unknown('leftover', 18).
ml_baseline_unknown('leftovers', 6).
ml_baseline_unknown('lego', 45).
ml_baseline_unknown('leila', 10).
ml_baseline_unknown('levi', 45).
ml_baseline_unknown('liam', 3).
ml_baseline_unknown('lilibeth', 24).
ml_baseline_unknown('lilith', 11).
ml_baseline_unknown('lillian', 8).
ml_baseline_unknown('lisa', 56).
ml_baseline_unknown('ll', 13).
ml_baseline_unknown('lopez', 8).
ml_baseline_unknown('lou', 6).
ml_baseline_unknown('louie', 10).
ml_baseline_unknown('lucian', 4).
ml_baseline_unknown('lyle', 9).
ml_baseline_unknown('m', 91).
ml_baseline_unknown('mabel', 9).
ml_baseline_unknown('mac', 9).
ml_baseline_unknown('mack', 2).
ml_baseline_unknown('madeline', 35).
ml_baseline_unknown('mai', 3).
ml_baseline_unknown('mailbox', 5).
ml_baseline_unknown('mandy', 8).
ml_baseline_unknown('manny', 9).
ml_baseline_unknown('marathon', 5).
ml_baseline_unknown('marco', 4).
ml_baseline_unknown('marcus', 14).
ml_baseline_unknown('marcy', 39).
ml_baseline_unknown('margaret', 3).
ml_baseline_unknown('marinara', 4).
ml_baseline_unknown('marissa', 8).
ml_baseline_unknown('marla', 8).
ml_baseline_unknown('marshmallow', 5).
ml_baseline_unknown('marshmallows', 14).
ml_baseline_unknown('martha', 19).
ml_baseline_unknown('marvin', 10).
ml_baseline_unknown('matilda', 14).
ml_baseline_unknown('matthew', 8).
ml_baseline_unknown('max', 49).
ml_baseline_unknown('mealworms', 16).
ml_baseline_unknown('meg', 42).
ml_baseline_unknown('megan', 2).
ml_baseline_unknown('meghan', 2).
ml_baseline_unknown('melanie', 56).
ml_baseline_unknown('michael', 8).
ml_baseline_unknown('michel', 10).
ml_baseline_unknown('midterms', 6).
ml_baseline_unknown('mikaela', 5).
ml_baseline_unknown('mike', 3).
ml_baseline_unknown('mila', 9).
ml_baseline_unknown('mileage', 7).
ml_baseline_unknown('milkshake', 4).
ml_baseline_unknown('milly', 7).
ml_baseline_unknown('min', 4).
ml_baseline_unknown('mini', 81).
ml_baseline_unknown('minis', 2).
ml_baseline_unknown('mitchell', 28).
ml_baseline_unknown('ml', 57).
ml_baseline_unknown('mom', 37).
ml_baseline_unknown('motorcycle', 5).
ml_baseline_unknown('motorcycles', 9).
ml_baseline_unknown('mph', 29).
ml_baseline_unknown('mr', 55).
ml_baseline_unknown('mrs', 37).
ml_baseline_unknown('ms', 36).
ml_baseline_unknown('muffaletta', 8).
ml_baseline_unknown('multi', 4).
ml_baseline_unknown('mustafa', 6).
ml_baseline_unknown('nadia', 6).
ml_baseline_unknown('nancy', 11).
ml_baseline_unknown('nate', 3).
ml_baseline_unknown('nd', 22).
ml_baseline_unknown('nearby', 4).
ml_baseline_unknown('necklaces', 1).
ml_baseline_unknown('neil', 12).
ml_baseline_unknown('newfound', 2).
ml_baseline_unknown('ney', 4).
ml_baseline_unknown('nicki', 8).
ml_baseline_unknown('nicole', 10).
ml_baseline_unknown('nida', 3).
ml_baseline_unknown('nigel', 27).
ml_baseline_unknown('nilo', 8).
ml_baseline_unknown('odds', 10).
ml_baseline_unknown('olaf', 12).
ml_baseline_unknown('olga', 27).
ml_baseline_unknown('olivia', 4).
ml_baseline_unknown('omar', 5).
ml_baseline_unknown('online', 4).
ml_baseline_unknown('oomyapeck', 8).
ml_baseline_unknown('openai', 2).
ml_baseline_unknown('oscar', 6).
ml_baseline_unknown('oz', 14).
ml_baseline_unknown('p', 13).
ml_baseline_unknown('pablo', 8).
ml_baseline_unknown('pace', 2).
ml_baseline_unknown('paige', 7).
ml_baseline_unknown('paperback', 4).
ml_baseline_unknown('patricia', 8).
ml_baseline_unknown('pepperoni', 16).
ml_baseline_unknown('percent', 35).
ml_baseline_unknown('percius', 3).
ml_baseline_unknown('percy', 3).
ml_baseline_unknown('piggy', 24).
ml_baseline_unknown('pima', 3).
ml_baseline_unknown('pizza', 24).
ml_baseline_unknown('pizzas', 22).
ml_baseline_unknown('playoff', 2).
ml_baseline_unknown('playoffs', 5).
ml_baseline_unknown('pm', 8).
ml_baseline_unknown('pokemon', 10).
ml_baseline_unknown('popcorn', 57).
ml_baseline_unknown('prepping', 20).
ml_baseline_unknown('priya', 2).
ml_baseline_unknown('promotional', 7).
ml_baseline_unknown('q', 2).
ml_baseline_unknown('queenie', 24).
ml_baseline_unknown('r', 13).
ml_baseline_unknown('rabbit', 14).
ml_baseline_unknown('rabbits', 29).
ml_baseline_unknown('rachel', 27).
ml_baseline_unknown('radio', 6).
ml_baseline_unknown('rainforest', 2).
ml_baseline_unknown('rancher', 30).
ml_baseline_unknown('randi', 14).
ml_baseline_unknown('randy', 30).
ml_baseline_unknown('raspberries', 8).
ml_baseline_unknown('rd', 20).
ml_baseline_unknown('rds', 2).
ml_baseline_unknown('re', 28).
ml_baseline_unknown('realised', 2).
ml_baseline_unknown('rebecca', 14).
ml_baseline_unknown('recommend', 2).
ml_baseline_unknown('recommendation', 1).
ml_baseline_unknown('recommended', 1).
ml_baseline_unknown('recovered', 5).
ml_baseline_unknown('rectangles', 20).
ml_baseline_unknown('rectangular', 12).
ml_baseline_unknown('recycle', 6).
ml_baseline_unknown('recycled', 10).
ml_baseline_unknown('recycling', 7).
ml_baseline_unknown('redeem', 4).
ml_baseline_unknown('redeemed', 4).
ml_baseline_unknown('redo', 4).
ml_baseline_unknown('reduce', 14).
ml_baseline_unknown('reduced', 9).
ml_baseline_unknown('reduces', 5).
ml_baseline_unknown('reduction', 2).
ml_baseline_unknown('refill', 15).
ml_baseline_unknown('refilling', 2).
ml_baseline_unknown('refills', 1).
ml_baseline_unknown('reflection', 1).
ml_baseline_unknown('refuel', 4).
ml_baseline_unknown('refunded', 1).
ml_baseline_unknown('reggie', 18).
ml_baseline_unknown('region', 8).
ml_baseline_unknown('regions', 1).
ml_baseline_unknown('regroup', 1).
ml_baseline_unknown('regular', 50).
ml_baseline_unknown('rehana', 12).
ml_baseline_unknown('rely', 1).
ml_baseline_unknown('relying', 1).
ml_baseline_unknown('remember', 1).
ml_baseline_unknown('remembers', 2).
ml_baseline_unknown('remind', 3).
ml_baseline_unknown('removed', 13).
ml_baseline_unknown('removing', 6).
ml_baseline_unknown('rena', 9).
ml_baseline_unknown('renovate', 2).
ml_baseline_unknown('repainting', 2).
ml_baseline_unknown('repay', 4).
ml_baseline_unknown('repeats', 6).
ml_baseline_unknown('replace', 3).
ml_baseline_unknown('report', 2).
ml_baseline_unknown('reported', 4).
ml_baseline_unknown('represent', 72).
ml_baseline_unknown('representation', 7).
ml_baseline_unknown('representations', 11).
ml_baseline_unknown('represented', 16).
ml_baseline_unknown('representing', 6).
ml_baseline_unknown('represents', 22).
ml_baseline_unknown('reps', 6).
ml_baseline_unknown('requested', 2).
ml_baseline_unknown('require', 13).
ml_baseline_unknown('required', 29).
ml_baseline_unknown('requirement', 5).
ml_baseline_unknown('requirements', 3).
ml_baseline_unknown('requires', 19).
ml_baseline_unknown('reread', 8).
ml_baseline_unknown('researchers', 2).
ml_baseline_unknown('reseeding', 4).
ml_baseline_unknown('reseeds', 4).
ml_baseline_unknown('respectfully', 1).
ml_baseline_unknown('response', 5).
ml_baseline_unknown('responses', 1).
ml_baseline_unknown('restart', 40).
ml_baseline_unknown('restarts', 5).
ml_baseline_unknown('restate', 99).
ml_baseline_unknown('restaurant', 21).
ml_baseline_unknown('restroom', 10).
ml_baseline_unknown('reusable', 1).
ml_baseline_unknown('rewind', 40).
ml_baseline_unknown('rewinding', 8).
ml_baseline_unknown('rewound', 4).
ml_baseline_unknown('reynald', 6).
ml_baseline_unknown('rho', 1).
ml_baseline_unknown('richard', 4).
ml_baseline_unknown('riverbed', 14).
ml_baseline_unknown('robi', 4).
ml_baseline_unknown('robot', 17).
ml_baseline_unknown('robotics', 2).
ml_baseline_unknown('ron', 11).
ml_baseline_unknown('rosie', 14).
ml_baseline_unknown('runoff', 3).
ml_baseline_unknown('ryan', 20).
ml_baseline_unknown('salisbury', 7).
ml_baseline_unknown('salsa', 6).
ml_baseline_unknown('samantha', 4).
ml_baseline_unknown('sammy', 22).
ml_baseline_unknown('samuel', 9).
ml_baseline_unknown('san', 1).
ml_baseline_unknown('sandbag', 4).
ml_baseline_unknown('sandoval', 18).
ml_baseline_unknown('sandra', 16).
ml_baseline_unknown('sang', 22).
ml_baseline_unknown('sangita', 7).
ml_baseline_unknown('sarah', 34).
ml_baseline_unknown('sarith', 20).
ml_baseline_unknown('saturday', 35).
ml_baseline_unknown('sausage', 8).
ml_baseline_unknown('seabed', 4).
ml_baseline_unknown('seahawks', 24).
ml_baseline_unknown('seattle', 24).
ml_baseline_unknown('sec', 5).
ml_baseline_unknown('semi', 6).
ml_baseline_unknown('servings', 6).
ml_baseline_unknown('shannen', 16).
ml_baseline_unknown('sharpener', 15).
ml_baseline_unknown('shawn', 4).
ml_baseline_unknown('shawna', 33).
ml_baseline_unknown('sheena', 6).
ml_baseline_unknown('sheila', 10).
ml_baseline_unknown('shelby', 9).
ml_baseline_unknown('shoebox', 6).
ml_baseline_unknown('shredded', 4).
ml_baseline_unknown('shrunk', 4).
ml_baseline_unknown('sibling', 1).
ml_baseline_unknown('siblings', 12).
ml_baseline_unknown('silas', 5).
ml_baseline_unknown('situp', 3).
ml_baseline_unknown('situps', 45).
ml_baseline_unknown('skier', 3).
ml_baseline_unknown('skiers', 2).
ml_baseline_unknown('skiing', 1).
ml_baseline_unknown('sloan', 8).
ml_baseline_unknown('smoothie', 1).
ml_baseline_unknown('soccer', 69).
ml_baseline_unknown('sofia', 5).
ml_baseline_unknown('softball', 2).
ml_baseline_unknown('softballs', 12).
ml_baseline_unknown('someone', 20).
ml_baseline_unknown('sonja', 10).
ml_baseline_unknown('sophia', 28).
ml_baseline_unknown('sourdough', 5).
ml_baseline_unknown('spacecraft', 2).
ml_baseline_unknown('spain', 12).
ml_baseline_unknown('spiderwebs', 7).
ml_baseline_unknown('splitting', 2).
ml_baseline_unknown('spotify', 4).
ml_baseline_unknown('spreadsheet', 1).
ml_baseline_unknown('sq', 8).
ml_baseline_unknown('sqrt', 2).
ml_baseline_unknown('squirrel', 24).
ml_baseline_unknown('squirrels', 28).
ml_baseline_unknown('sr', 1).
ml_baseline_unknown('st', 16).
ml_baseline_unknown('starshaped', 1).
ml_baseline_unknown('stashed', 2).
ml_baseline_unknown('stephen', 2).
ml_baseline_unknown('stockpiling', 8).
ml_baseline_unknown('stopover', 2).
ml_baseline_unknown('striploin', 2).
ml_baseline_unknown('stuart', 20).
ml_baseline_unknown('suddenly', 2).
ml_baseline_unknown('sunscreen', 4).
ml_baseline_unknown('supermajorities', 1).
ml_baseline_unknown('susan', 6).
ml_baseline_unknown('sustainably', 3).
ml_baseline_unknown('suv', 15).
ml_baseline_unknown('tabitha', 8).
ml_baseline_unknown('taco', 7).
ml_baseline_unknown('tacos', 17).
ml_baseline_unknown('taken', 44).
ml_baseline_unknown('talia', 50).
ml_baseline_unknown('tania', 2).
ml_baseline_unknown('tanya', 22).
ml_baseline_unknown('tara', 2).
ml_baseline_unknown('tasha', 8).
ml_baseline_unknown('tavernmaster', 2).
ml_baseline_unknown('tayzia', 15).
ml_baseline_unknown('teammates', 2).
ml_baseline_unknown('teddies', 11).
ml_baseline_unknown('teddy', 2).
ml_baseline_unknown('tedra', 8).
ml_baseline_unknown('television', 10).
ml_baseline_unknown('televisions', 36).
ml_baseline_unknown('textbook', 26).
ml_baseline_unknown('th', 47).
ml_baseline_unknown('theirs', 1).
ml_baseline_unknown('themed', 13).
ml_baseline_unknown('thiswarmup', 1).
ml_baseline_unknown('threedimensional', 1).
ml_baseline_unknown('thumbtack', 2).
ml_baseline_unknown('thumbtacks', 1).
ml_baseline_unknown('tim', 24).
ml_baseline_unknown('timmy', 9).
ml_baseline_unknown('tina', 12).
ml_baseline_unknown('today', 104).
ml_baseline_unknown('todd', 36).
ml_baseline_unknown('toenails', 40).
ml_baseline_unknown('tonya', 9).
ml_baseline_unknown('totaling', 3).
ml_baseline_unknown('toula', 24).
ml_baseline_unknown('tracy', 30).
ml_baseline_unknown('trevor', 32).
ml_baseline_unknown('tripped', 2).
ml_baseline_unknown('trivia', 1).
ml_baseline_unknown('ts', 1).
ml_baseline_unknown('tsunami', 8).
ml_baseline_unknown('tv', 19).
ml_baseline_unknown('twodigit', 1).
ml_baseline_unknown('typically', 6).
ml_baseline_unknown('tyson', 12).
ml_baseline_unknown('unclear', 6).
ml_baseline_unknown('undetected', 3).
ml_baseline_unknown('undried', 2).
ml_baseline_unknown('unfollowed', 4).
ml_baseline_unknown('unfortunately', 4).
ml_baseline_unknown('ungridded', 1).
ml_baseline_unknown('unicycle', 16).
ml_baseline_unknown('uninterrupted', 8).
ml_baseline_unknown('unnoticed', 2).
ml_baseline_unknown('unoccupied', 4).
ml_baseline_unknown('unproductive', 1).
ml_baseline_unknown('unsold', 18).
ml_baseline_unknown('unsure', 1).
ml_baseline_unknown('upcoming', 7).
ml_baseline_unknown('update', 5).
ml_baseline_unknown('updates', 10).
ml_baseline_unknown('usually', 6).
ml_baseline_unknown('ve', 11).
ml_baseline_unknown('vegetables', 34).
ml_baseline_unknown('vet', 3).
ml_baseline_unknown('video', 96).
ml_baseline_unknown('videos', 14).
ml_baseline_unknown('village', 10).
ml_baseline_unknown('visitors', 54).
ml_baseline_unknown('vloggers', 2).
ml_baseline_unknown('volleyballs', 12).
ml_baseline_unknown('voltaire', 6).
ml_baseline_unknown('w', 7).
ml_baseline_unknown('walled', 12).
ml_baseline_unknown('wallpaper', 24).
ml_baseline_unknown('walmart', 12).
ml_baseline_unknown('wanda', 12).
ml_baseline_unknown('was30', 2).
ml_baseline_unknown('wasn', 9).
ml_baseline_unknown('wayne', 1).
ml_baseline_unknown('website', 2).
ml_baseline_unknown('wednesday', 66).
ml_baseline_unknown('wednesdays', 4).
ml_baseline_unknown('weekday', 24).
ml_baseline_unknown('weekdays', 29).
ml_baseline_unknown('weekend', 47).
ml_baseline_unknown('weekends', 30).
ml_baseline_unknown('weeknights', 4).
ml_baseline_unknown('wendi', 40).
ml_baseline_unknown('wendy', 20).
ml_baseline_unknown('weren', 1).
ml_baseline_unknown('wes', 3).
ml_baseline_unknown('widget', 4).
ml_baseline_unknown('widgets', 6).
ml_baseline_unknown('william', 24).
ml_baseline_unknown('willowton', 4).
ml_baseline_unknown('wilson', 4).
ml_baseline_unknown('winston', 9).
ml_baseline_unknown('woke', 4).
ml_baseline_unknown('workout', 6).
ml_baseline_unknown('x', 2699).
ml_baseline_unknown('xavier', 20).
ml_baseline_unknown('xena', 14).
ml_baseline_unknown('xl', 9).
ml_baseline_unknown('yd', 5).
ml_baseline_unknown('york', 2).
ml_baseline_unknown('yulia', 10).
ml_baseline_unknown('zap', 4).
ml_baseline_unknown('zapped', 6).
ml_baseline_unknown('zero', 3).
ml_baseline_unknown('zeros', 1).
ml_baseline_unknown('zika', 6).
ml_baseline_unknown('zombies', 22).
ml_baseline_unknown('zoo', 2).
ml_baseline_unknown('zubir', 4).
ml_baseline_unknown('zucchini', 8).
ml_baseline_unknown('π', 2).
ml_baseline_unknown('πr', 5).

% The tracked questioning-paper alternatives absorbed by this store.
ml_source_term(questioning_paper_lexicon, 'equation', tokens(['equation'])).
ml_source_term(questioning_paper_lexicon, 'expression', tokens(['expression'])).
ml_source_term(questioning_paper_lexicon, 'sum', tokens(['sum'])).
ml_source_term(questioning_paper_lexicon, 'difference', tokens(['difference'])).
ml_source_term(questioning_paper_lexicon, 'product', tokens(['product'])).
ml_source_term(questioning_paper_lexicon, 'quotient', tokens(['quotient'])).
ml_source_term(questioning_paper_lexicon, 'factor', tokens(['factor'])).
ml_source_term(questioning_paper_lexicon, 'multiple', tokens(['multiple'])).
ml_source_term(questioning_paper_lexicon, 'remainder', tokens(['remainder'])).
ml_source_term(questioning_paper_lexicon, 'addend', tokens(['addend'])).
ml_source_term(questioning_paper_lexicon, 'denominator', tokens(['denominator'])).
ml_source_term(questioning_paper_lexicon, 'numerator', tokens(['numerator'])).
ml_source_term(questioning_paper_lexicon, 'fraction', tokens(['fraction'])).
ml_source_term(questioning_paper_lexicon, 'decimal', tokens(['decimal'])).
ml_source_term(questioning_paper_lexicon, 'percent', tokens(['percent'])).
ml_source_term(questioning_paper_lexicon, 'ratio', tokens(['ratio'])).
ml_source_term(questioning_paper_lexicon, 'rate', tokens(['rate'])).
ml_source_term(questioning_paper_lexicon, 'unit', tokens(['unit'])).
ml_source_term(questioning_paper_lexicon, 'place value', tokens(['place', 'value'])).
ml_source_term(questioning_paper_lexicon, 'tens', tokens(['tens'])).
ml_source_term(questioning_paper_lexicon, 'ones', tokens(['ones'])).
ml_source_term(questioning_paper_lexicon, 'hundreds', tokens(['hundreds'])).
ml_source_term(questioning_paper_lexicon, 'regroup', tokens(['regroup'])).
ml_source_term(questioning_paper_lexicon, 'compose', tokens(['compose'])).
ml_source_term(questioning_paper_lexicon, 'decompose', tokens(['decompose'])).
ml_source_term(questioning_paper_lexicon, 'associative', tokens(['associative'])).
ml_source_term(questioning_paper_lexicon, 'commutative', tokens(['commutative'])).
ml_source_term(questioning_paper_lexicon, 'distributive', tokens(['distributive'])).
ml_source_term(questioning_paper_lexicon, 'equivalent', tokens(['equivalent'])).
ml_source_term(questioning_paper_lexicon, 'equal', tokens(['equal'])).
ml_source_term(questioning_paper_lexicon, 'inequality', tokens(['inequality'])).
ml_source_term(questioning_paper_lexicon, 'variable', tokens(['variable'])).
ml_source_term(questioning_paper_lexicon, 'coefficient', tokens(['coefficient'])).
ml_source_term(questioning_paper_lexicon, 'slope', tokens(['slope'])).
ml_source_term(questioning_paper_lexicon, 'intercept', tokens(['intercept'])).
ml_source_term(questioning_paper_lexicon, 'function', tokens(['function'])).
ml_source_term(questioning_paper_lexicon, 'perimeter', tokens(['perimeter'])).
ml_source_term(questioning_paper_lexicon, 'area', tokens(['area'])).
ml_source_term(questioning_paper_lexicon, 'volume', tokens(['volume'])).
ml_source_term(questioning_paper_lexicon, 'angle', tokens(['angle'])).
ml_source_term(questioning_paper_lexicon, 'vertex', tokens(['vertex'])).
ml_source_term(questioning_paper_lexicon, 'vertices', tokens(['vertices'])).
ml_source_term(questioning_paper_lexicon, 'parallel', tokens(['parallel'])).
ml_source_term(questioning_paper_lexicon, 'perpendicular', tokens(['perpendicular'])).
ml_source_term(questioning_paper_lexicon, 'congruent', tokens(['congruent'])).
ml_source_term(questioning_paper_lexicon, 'similar', tokens(['similar'])).
ml_source_term(questioning_paper_lexicon, 'symmetry', tokens(['symmetry'])).
ml_source_term(questioning_paper_lexicon, 'transformation', tokens(['transformation'])).
ml_source_term(questioning_paper_lexicon, 'translation', tokens(['translation'])).
ml_source_term(questioning_paper_lexicon, 'rotation', tokens(['rotation'])).
ml_source_term(questioning_paper_lexicon, 'reflection', tokens(['reflection'])).
ml_source_term(questioning_paper_lexicon, 'dilation', tokens(['dilation'])).
ml_source_term(questioning_paper_lexicon, 'mean', tokens(['mean'])).
ml_source_term(questioning_paper_lexicon, 'median', tokens(['median'])).
ml_source_term(questioning_paper_lexicon, 'mode', tokens(['mode'])).
ml_source_term(questioning_paper_lexicon, 'range', tokens(['range'])).
ml_source_term(questioning_paper_lexicon, 'distribution', tokens(['distribution'])).
ml_source_term(questioning_paper_lexicon, 'scatter', tokens(['scatter'])).
ml_source_term(questioning_paper_lexicon, 'association', tokens(['association'])).
ml_source_term(questioning_paper_lexicon, 'array', tokens(['array'])).
ml_source_term(questioning_paper_lexicon, 'number line', tokens(['number', 'line'])).
ml_source_term(questioning_paper_lexicon, 'tape diagram', tokens(['tape', 'diagram'])).
ml_source_term(questioning_paper_lexicon, 'base[- ]ten', tokens(['base', 'ten'])).
ml_source_term(questioning_paper_lexicon, 'ten[- ]frame', tokens(['ten', 'frame'])).
ml_source_term(questioning_paper_lexicon, 'partition', tokens(['partition'])).
ml_source_term(questioning_paper_lexicon, 'multiplication', tokens(['multiplication'])).
ml_source_term(questioning_paper_lexicon, 'division', tokens(['division'])).
ml_source_term(questioning_paper_lexicon, 'addition', tokens(['addition'])).
ml_source_term(questioning_paper_lexicon, 'subtraction', tokens(['subtraction'])).
ml_source_term(questioning_paper_lexicon, 'exponent', tokens(['exponent'])).
ml_source_term(questioning_paper_lexicon, 'square root', tokens(['square', 'root'])).
ml_source_term(questioning_paper_lexicon, 'integer', tokens(['integer'])).
ml_source_term(questioning_paper_lexicon, 'negative', tokens(['negative'])).
ml_source_term(questioning_paper_lexicon, 'positive', tokens(['positive'])).
ml_source_term(questioning_paper_lexicon, 'absolute value', tokens(['absolute', 'value'])).
ml_source_term(questioning_paper_lexicon, 'coordinate', tokens(['coordinate'])).
ml_source_term(questioning_paper_lexicon, 'proportional', tokens(['proportional'])).
ml_source_term(questioning_paper_lexicon, 'scale factor', tokens(['scale', 'factor'])).

math_lexicon_pilot_summary(summary(ml_words(5006), ml_unknowns(19), baseline_unknowns(764), math_terms(78), question_records(2621), dataset_records(2004), token_occurrences(question_corpus(10341), dataset(123138)))).
ml_expected_counts(5006, 19, 764, 78).

check_math_lexicon_pilot :-
    ml_expected_counts(ExpectedWords, ExpectedUnknowns, ExpectedBaseline, ExpectedTerms),
    aggregate_all(count, ml_word(_, _, _, _), ExpectedWords),
    aggregate_all(count, ml_unknown(_, _), ExpectedUnknowns),
    aggregate_all(count, ml_baseline_unknown(_, _), ExpectedBaseline),
    aggregate_all(count, ml_source_term(questioning_paper_lexicon, _, _), ExpectedTerms),
    forall(ml_baseline_unknown(Word, _), em_word_class(Word, _)),
    forall(ml_word(Base, Category, forms(Forms), _),
           forall(member(Form, Forms), morphology_receipt(Base, Category, Form))),
    forall(ml_source_term(questioning_paper_lexicon, _, tokens(Tokens)),
           forall(member(Token, Tokens), absorbed_questioning_token(Token))),
    writeln('math_lexicon_pilot: all receipts passed').

morphology_receipt(Base, noun, Form) :- em_noun_base(Form, Base), !.
morphology_receipt(Base, verb, Form) :- em_verb_base(Form, Base, _), !.
morphology_receipt(Base, adjective, Form) :- em_adjective_base(Form, Base, _), !.
morphology_receipt(Base, domain, Form) :- Base == Form, em_math_domain(Form), !.
morphology_receipt(Base, Category, Form) :-
    memberchk(Category, [adverb, preposition, pronoun, conjunction, interjection]),
    Base == Form, em_category(Form, Category), !.
morphology_receipt(Base, Category, Form) :-
    Base == Form, em_word_class(Form, Category), !.
morphology_receipt(Base, Category, Form) :-
    format(user_error, 'unresolved morphology: ~q ~q ~q~n', [Base, Category, Form]),
    fail.

absorbed_questioning_token(Token) :-
    ml_word(_, _, forms(Forms), demand(Demand)),
    memberchk(questioning_paper_lexicon, Demand), memberchk(Token, Forms), !.
absorbed_questioning_token(Token) :- ml_unknown(Token, _), !.
