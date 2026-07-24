# Literature Docling array on Big Red

This directory runs one Slurm task for each of the 12 journal directories. The
driver writes one Markdown file and one JSON sidecar atomically after each PDF.
A repeated task validates those checkpoints and skips completed PDFs. A parent
Python process gives each conversion an external wall-clock limit, writes an
explicit `*.error.json` record on failure, and continues with the next PDF.

Figure description is a separate pass. The array records page and bounding-box
locators for each figure. It does not call a model, which keeps text conversion
independent of model access on compute nodes.

## Input layout

The job reads these paths by default:

```text
research_corpus/pdfs/{ESM,FLM,IJEMST,IJMEST,IJSME,JMB,JMTE,JRME,MERJ,MTL,RME,ZDM}/
research_corpus/references.bib
data/research/references.bib
```

If the corpus is staged elsewhere, set `LITERATURE_CORPUS_ROOT` to the `pdfs`
directory and `LITERATURE_CORPUS_BIB` to its `references.bib`. The source
corpus remains read-only.

## Configure and submit

Replace `REPLACE_WITH_BIG_RED_ACCOUNT` in `job.slurm`. Slurm opens its output
files before the script body runs, so create the scheduler log directory before
submitting:

```bash
mkdir -p scripts/bigred/literature_docling/logs
sbatch scripts/bigred/literature_docling/job.slurm
```

The default per-PDF watchdog is 1,800 seconds. Change it at submission when
needed:

```bash
sbatch --export=ALL,LITERATURE_PDF_TIMEOUT=2400 \
  scripts/bigred/literature_docling/job.slurm
```

Submit the same array again after a cancellation or wall timeout. `--resume`
keeps every valid per-PDF checkpoint. Failure records remain inspectable and a
later run retries those PDFs because only complete sidecars count as
checkpoints.

## Collect and merge

Copy the remote output without deleting it. Then build the deterministic
query index inside the collected tree:

```bash
python3 scripts/bigred/literature_docling/collect_merge.py \
  /path/to/collected/literature \
  --require-all-journals
```

The helper writes `corpus_index.jsonl`, `corpus_failures.jsonl`, and
`corpus_manifest.json`. It sorts by journal and source filename and writes no
timestamps, so identical checkpoints produce identical merged bytes.

After collecting all text conversions, create the second-pass figure request
manifest:

```bash
python3 scripts/research/literature_intake.py \
  --description-manifest \
  --output-root /path/to/collected/literature
```

Each request contains the PDF locator, page number, crop bounding box, caption,
and the required Granite-style response fields. A later controller-side model
runner can fill those fields without repeating Docling conversion.
