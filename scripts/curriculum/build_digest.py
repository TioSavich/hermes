#!/usr/bin/env python3
"""Build a teacher-facing lesson digest fact store from the vision harvest.

For every extracted IM lesson: its goals, the Common Core standards it works on,
the exact computations it contains (with answers, page, and whether the operand
was figure-bound), the errors it anticipates, and the honest developmental
boundary. This is a teacher resource — "what does this lesson demand, what
standards, what will students compute, where might they stumble" — not just
compiler input. Regenerates lessons/im/generated/vision_lesson_digest.pl from
scripts/curriculum/vision_harvest/im_g6_8_vision_harvest.json.
"""
import os, json, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    REPO, "lessons", "im", "generated", "vision_lesson_digest.pl")

def pstr(s):
    s = (s or "").replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ").strip()
    return '"' + s + '"'

def patom(s):
    return "'" + str(s).replace("\\", "\\\\").replace("'", "\\'") + "'"

def ccss_atom(code):
    # CCSS codes like 6.NS.B.2 -> keep as a quoted atom
    return patom(code.strip())

lessons = json.load(open(os.path.join(os.path.dirname(__file__),"vision_harvest/im_g6_8_vision_harvest.json")))
lessons.sort(key=lambda L: (L["grade"], L["unit"], L["lesson"]))

lines = [
    "/** <module> Teacher-facing lesson digest from the vision harvest of the",
    " *  Illustrative Mathematics 6-8 teacher guides (2026-07-12).",
    " *",
    " *  One structured record per lesson: goals, Common Core standards, the exact",
    " *  computations the lesson contains (with answers, page, and whether the",
    " *  operand was recovered from a figure a text extractor drops), anticipated",
    " *  student errors, and the honest developmental boundary. Source-cited; a",
    " *  cache with provenance, not an authority. Regenerate with",
    " *  scripts/curriculum/build_digest.py from the vision run.",
    " */",
    ":- module(vision_lesson_digest,",
    "          [ vision_lesson/5,",
    "            vision_lesson_goal/3,",
    "            vision_lesson_purpose/2,",
    "            vision_lesson_standard/3,",
    "            vision_lesson_computation/6,",
    "            vision_lesson_error/4,",
    "            vision_lesson_boundary/2,",
    "            vision_lessons_for_standard/2,",
    "            vision_lesson_digest_summary/2",
    "          ]).",
    "",
    ":- discontiguous vision_lesson/5, vision_lesson_goal/3, vision_lesson_purpose/2,",
    "     vision_lesson_standard/3, vision_lesson_computation/6, vision_lesson_error/4,",
    "     vision_lesson_boundary/2.",
    "",
]

n_comp = n_std = n_err = n_fig = 0
for L in lessons:
    code = L["code"]; g, u, ln = L["grade"], L["unit"], L["lesson"]
    lines.append(f"vision_lesson({patom(code)}, {g}, {u}, {ln}, {pstr(L.get('title',''))}).")
    for gl in (L.get("teacher_goals") or []):
        lines.append(f"vision_lesson_goal({patom(code)}, teacher, {pstr(gl)}).")
    if L.get("student_facing_goal"):
        lines.append(f"vision_lesson_goal({patom(code)}, student, {pstr(L['student_facing_goal'])}).")
    if L.get("purpose"):
        lines.append(f"vision_lesson_purpose({patom(code)}, {pstr(L['purpose'])}).")
    st = L.get("standards") or {}
    for band in ("building_on", "addressing", "building_toward"):
        for c in st.get(band, []) or []:
            lines.append(f"vision_lesson_standard({patom(code)}, {band}, {ccss_atom(c)}).")
            n_std += 1
    for t in L.get("task_events", []):
        kind = t.get("kind", ""); op = t.get("op", "")
        origin = "figure" if t.get("figure_bound") else "text"
        n_fig += 1 if t.get("figure_bound") else 0
        lines.append(
            f"vision_lesson_computation({patom(code)}, {pstr(t.get('task',''))}, "
            f"{pstr(str(t.get('answer','')))}, {patom((t.get('position','') or 'activity')[:40])}, "
            f"{pstr(str(t.get('pages','')))}, {origin}).")
        n_comp += 1
        d = t.get("deformation")
        if d:
            lines.append(
                f"vision_lesson_error({patom(code)}, {patom(d.get('family','error'))}, "
                f"{pstr(str(d.get('wrong_answer','')))}, {pstr(d.get('excerpt',''))}).")
            n_err += 1
    if L.get("boundary_note"):
        lines.append(f"vision_lesson_boundary({patom(code)}, {pstr(L['boundary_note'][:600])}).")
    lines.append("")

# teacher query helpers
lines += [
    "%!  vision_lessons_for_standard(+CCSS, -Codes) is det.",
    "%   Every extracted lesson that works on a Common Core standard (any band).",
    "vision_lessons_for_standard(CCSS, Codes) :-",
    "    findall(Code, vision_lesson_standard(Code, _Band, CCSS), Codes0),",
    "    sort(Codes0, Codes).",
    "",
    "%!  vision_lesson_digest_summary(+Code, -Summary) is semidet.",
    "%   A compact teacher-facing dict for one lesson.",
    "vision_lesson_digest_summary(Code, Summary) :-",
    "    vision_lesson(Code, G, U, L, Title),",
    "    findall(T, vision_lesson_goal(Code, teacher, T), Goals),",
    "    ( vision_lesson_purpose(Code, P) -> Purpose = P ; Purpose = \"\" ),",
    "    findall(S-C, vision_lesson_standard(Code, S, C), Stds),",
    "    findall(Task-Ans, vision_lesson_computation(Code, Task, Ans, _, _, _), Comps),",
    "    findall(F-W, vision_lesson_error(Code, F, W, _), Errors),",
    "    ( vision_lesson_boundary(Code, B) -> Boundary = B ; Boundary = none ),",
    "    Summary = digest{code:Code, grade:G, unit:U, lesson:L, title:Title,",
    "                     goals:Goals, purpose:Purpose, standards:Stds,",
    "                     computations:Comps, anticipated_errors:Errors,",
    "                     boundary:Boundary}.",
    "",
]

open(OUT, "w").write("\n".join(lines))
print(f"wrote {OUT}")
print(f"lessons={len(lessons)} computations={n_comp} (figure-bound={n_fig}) standards={n_std} errors={n_err}")
