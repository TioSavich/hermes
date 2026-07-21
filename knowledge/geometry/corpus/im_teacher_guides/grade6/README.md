# Grade 6 teacher-guide extracts

Converted 2026-07-11 from the IM lesson PDFs in Tio's E343 curriculum
materials (`~/Desktop/E343_Cleanup/E343/Curriculum Materials/6th/`) with
`pdftotext -layout`. This is the first grade-6 material in the corpus; the
K-5 tree was already present, and grades 7-8 remain absent.

Two caveats that differ from the K-5 tree:

1. **Coverage is partial and uneven.** These PDFs are the slices Tio uses in
   E343: Unit 8 (data) has per-lesson files for lessons 1, 9, and 14 plus
   multi-lesson extracts; Unit 2 (ratios) and the decimal/fraction/percent
   material are multi-lesson extracts only. This is not the full grade-6
   curriculum.
2. **Files prefixed `extract_` span several lessons** and do not follow the
   one-lesson-per-file convention the compiler's LessonDoc assumes. Wire them
   into `compile_action_mappings.py` only after deciding how multi-lesson
   documents carry per-lesson provenance; until then they serve the reader
   lane.

Math rendered as images in the source PDFs is not captured by the text
conversion. Figure-carried operands recovered by direct PDF reading live in
`scripts/curriculum/pdf_recovered_candidates.json`.
