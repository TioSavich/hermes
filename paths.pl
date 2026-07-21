/** <module> Module search paths for modularized codebase
 *
 * Load this file before any module to set up file_search_path so
 * use_module directives resolve across module boundaries.
 *
 * Usage: swipl -l paths.pl -l formal/learner/server.pl
 *    or: :- [paths].  at the top of an entry point
 */

:- multifile user:file_search_path/2.
:- dynamic user:file_search_path/2.

:- prolog_load_context(directory, PrologRoot),
   forall(member(Alias-Relative,
                 [ pml-'formal/pml',
                   sequent-'formal/sequent',
                   incompat-'formal/incompatibility',
                   dialectic-'formal/dialectic',
                   juncture-'formal/juncture',
                   strategies-'knowledge/strategies',
                   learner-'formal/learner',
                   formalization-'formal/formalization',
                   misconceptions-'knowledge/misconceptions',
                   lessons-'curriculum',
                   hermes-'hermes',
                   geometry-'knowledge/geometry',
                   tools-'formal/tools',
                   carving-'formal/tools/carving',
                   standards-'knowledge/standards',
                   crosswalk-'knowledge/crosswalk',
                   zeeman-'more-zeeman/prolog'
                 ]),
          ( directory_file_path(PrologRoot, Relative, Absolute),
            ( user:file_search_path(Alias, Absolute)
            -> true
            ;  asserta(user:file_search_path(Alias, Absolute))
            )
          )).

:- forall(member(Alias-Spec,
                 [ math-strategies('math'),
                   render-strategies('render'),
                   standard_ccss-standards('ccss'),
                   standard_im-standards('im'),
                   standard_indiana-standards('indiana'),
                   im_lessons-lessons('im'),
                   strategy_standards-standards('indiana'),
                   meta-strategies('meta')
                 ]),
          ( user:file_search_path(Alias, Spec)
          -> true
          ;  asserta(user:file_search_path(Alias, Spec))
          )).

% Shared witness construction is foundational for crosswalk, geometry, and
% standards modules, including isolated module loads through this path setup.
:- use_module(formalization(witness_dict), []).

% Public figure corpus entrypoint used by representation/gallery checks.
:- use_module(lessons('im/docling_figures_interpreted'),
              [ docling_figure_rich/8 ]).
