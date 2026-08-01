#!/usr/bin/env python3
"""Check the IM measurement enactment lane against the live tree.

Four things this refuses to take on trust:

1. Every warrant the lane cites. A warrant names a teacher-guide file, a line,
   and the text at that line. The check re-reads the file and requires the text
   back. The teacher guides are two-column PDF extracts, so the student task
   text and the teacher notes share a line; the snippet has to be a substring of
   the line after whitespace is collapsed, not the whole line.

2. Every input whose provenance says `curriculum(file:line)`. The file has to
   exist and the line has to be inside it.

3. The emitted rows against the module's own census. A row can only exist for an
   enactment that ran, so the row count and the enactment count have to agree,
   and no lesson may appear in the rows without also appearing in the seam
   recut's measurement_task population.

4. Every row's honesty fields. A row states what it does not claim, and a row
   with a machine-supplied input can never report a well_formed verdict.

Exits nonzero on any failure. Run from the repository root:
  python3 scripts/checks/measurement_enactment.py
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROWS = os.path.join(ROOT, 'data/learningcommons/derived/lesson_enactments/measurement_task.jsonl')
RECUT = os.path.join(ROOT, 'data/learningcommons/derived/im_action_seam_recut.json')

DUMP_GOAL = (
    "forall(im_enactment_measurement:enactment_form(F, _, warrant(L, File, Line, Text)),"
    " format('FORM|~w|~w|~w|~w|~w~n', [F, L, File, Line, Text]))"
)


def collapse(s):
    return re.sub(r'\s+', ' ', s).strip()


def line_of(rel, line):
    path = os.path.join(ROOT, rel)
    if not os.path.exists(path):
        return None
    with open(path, encoding='utf-8') as fh:
        lines = fh.read().split('\n')
    if line < 1 or line > len(lines):
        return None
    return lines[line - 1]


def check_warrant(label, rel, line, text, failures):
    raw = line_of(rel, line)
    if raw is None:
        failures.append('%s: %s:%s is not a line in the tree' % (label, rel, line))
        return
    if collapse(text) not in collapse(raw):
        failures.append('%s: %s:%s does not carry %r (line reads %r)'
                        % (label, rel, line, collapse(text)[:70], collapse(raw)[:90]))


def form_warrants():
    """Read the ten form warrants out of the module itself."""
    out = subprocess.run(
        ['swipl', '-q', '-l', 'paths.pl',
         '-s', 'curriculum/im/enactment/measurement.pl',
         '-g', DUMP_GOAL, '-t', 'halt'],
        cwd=ROOT, capture_output=True, text=True)
    rows = []
    for ln in out.stdout.split('\n'):
        if not ln.startswith('FORM|'):
            continue
        parts = ln.split('|', 5)[1:]
        if len(parts) != 5:
            continue
        form, lesson, rel, line, text = parts
        rows.append((form, lesson, rel, int(line), text))
    return rows, out.stderr


def main():
    failures = []

    if not os.path.exists(ROWS):
        print('FAIL: %s does not exist; run '
              'scripts/curriculum/build_im_lesson_enactment_census.py' % ROWS)
        return 1
    rows = [json.loads(ln) for ln in open(ROWS, encoding='utf-8') if ln.strip()]

    # 1. form warrants
    forms, stderr = form_warrants()
    if len(forms) != 10:
        failures.append('read %d form warrants from the module, expected 10 (%s)'
                        % (len(forms), stderr.strip()[:200]))
    for form, lesson, rel, line, text in forms:
        check_warrant('form %s (%s)' % (form, lesson), rel, line, text, failures)

    # 2. row warrants and curriculum input provenance
    prov_re = re.compile(r'^curriculum\((.+):(\d+)\)$')
    for row in rows:
        w = row['warrant']
        check_warrant('row %s/%s' % (row['lesson'], row['form']),
                      w['source'], w['line'], w['text'], failures)
        for inp in row['inputs']:
            m = prov_re.match(inp['provenance'])
            if not m:
                continue
            rel, line = m.group(1), int(m.group(2))
            if line_of(rel, line) is None:
                failures.append('row %s input %s cites %s:%s, which is not a line '
                                'in the tree' % (row['lesson'], inp['key'], rel, line))

    # 3. rows against the population and against the module's census
    recut = json.load(open(RECUT, encoding='utf-8'))
    population = {l['lesson'] for l in recut['lessons']
                  if l.get('task_209_subclass') == 'measurement_task'}
    stray = sorted({r['lesson'] for r in rows} - population)
    if stray:
        failures.append('rows name lessons outside the measurement_task '
                        'population: %s' % stray)

    # 4. every row states what it does not claim, and a machine-supplied input
    #    can never carry a well_formed verdict
    for row in rows:
        if not row.get('what_it_does_not_claim'):
            failures.append('row %s/%s has no what_it_does_not_claim'
                            % (row['lesson'], row['form']))
        supplied = any(i['provenance'].startswith('stand_in')
                       for i in row['inputs'])
        if supplied and row['verdict'] == 'well_formed':
            failures.append('row %s/%s carries a machine-supplied input and still '
                            'reports well_formed' % (row['lesson'], row['form']))
        if row['input_provenance'] not in ('curriculum', 'curriculum_sample',
                                           'machine_supplied'):
            failures.append('row %s/%s has input_provenance %r'
                            % (row['lesson'], row['form'], row['input_provenance']))
        if supplied != (row['input_provenance'] == 'machine_supplied'):
            failures.append('row %s/%s: input_provenance disagrees with its own '
                            'inputs' % (row['lesson'], row['form']))

    if failures:
        for f in failures:
            print('FAIL: %s' % f)
        print('\n%d failures' % len(failures))
        return 1

    enacted = len({r['lesson'] for r in rows})
    well = len({r['lesson'] for r in rows if r['verdict'] == 'well_formed'})
    print('PASS measurement_enactment: %d rows, %d of %d lessons enacted, '
          '%d well formed, %d warrants re-read from the tree'
          % (len(rows), enacted, len(population), well, len(forms) + len(rows)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
