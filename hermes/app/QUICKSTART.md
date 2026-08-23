# Hermes Quickstart

This guide gets Hermes running on your own laptop and walks one discussion all the
way through. It assumes you can open a terminal and copy-paste a few commands. It
does **not** assume you know Prolog or Python.

Hermes is a console you run locally — a small web page served from your own machine
at `http://127.0.0.1:8765`. Nothing is published anywhere.

The whole setup is three steps. Budget about fifteen minutes the first time.

---

## Step 1 — Install SWI-Prolog

Hermes reads its scoring rules from a Prolog knowledge base, so it needs the
SWI-Prolog interpreter (`swipl`) on your machine.

1. Go to **https://www.swi-prolog.org/download/stable** and install the version for
   your operating system (there is a normal macOS and Windows installer).
2. Open a terminal and confirm it is installed:

   ```bash
   swipl --version
   ```

   You should see a line like `SWI-Prolog version 9.2.9 ...`. If instead you see
   "command not found," the install did not finish or did not add `swipl` to your
   PATH — re-run the installer and, on macOS, you may need to reopen the terminal.

You also need **Python 3** (most Macs already have it). Check with `python3
--version`. If that prints a version number, you are set.

---

## Step 2 — Get and enter your REALLMS key

Hermes uses REALLMS — IU's hosted language-model service — to write the prose parts
(student profiles, draft feedback). You need an API key for it. The key is a string
that starts with `sk-`.

- If you do not have a key yet, ask whoever set up your REALLMS access (Tio, or IU
  Research Technologies). Hermes cannot make a key for you.
- Once you have it, you can enter it two ways:
  - **In the app** (easiest): start Hermes (step 3), then click **Set key** in the
    top-right corner and paste the key. It is saved to
    `hermes/app/runtime/.env` on your laptop and is never committed to the
    repository.
  - **By hand**: create a file `hermes/app/runtime/.env` containing one line —
    `REALLMS_API_KEY=sk-...your-key...`.

The symbolic surfaces — the **Explore** and **Encyclopedia** tabs: strategy
runs, misconception checks, lesson charts, the visualizers — work without a
key. Everything that writes prose, including **Ask Hermes** replies, needs
the key.

---

## Step 3 — Start Hermes

From the repository's top folder, run:

```bash
./hermes/app/launch.sh
```

It starts the local server and opens your browser to `http://127.0.0.1:8765`. Leave
the terminal window open while you work; closing it stops Hermes. To stop on
purpose, press `Ctrl-C` in that terminal.

If `./hermes/app/launch.sh` reports a permission error, run it as
`bash hermes/app/launch.sh` instead.

---

## Try the synthetic example

To rehearse the whole workflow with made-up students, seed the synthetic example
and launch normally:

```bash
bash hermes/app/examples/seed.sh          # copies the synthetic roster + discussion
./hermes/app/launch.sh
```

---

## The happy path — one discussion, start to finish

The whole workflow lives on the console's **Workspace** tab as lettered
steps: **Parse → Profiles → Pairing page → Grades → Results**. Here it is
with the synthetic example already in place, so you can follow along before
using your own class.

1. **Parse.** This step turns a Canvas discussion paste into scored,
   structured data. The path field already points at
   `input/All_Discussions.txt` (the synthetic discussion). Click **Parse**,
   then **LLM rubric score**, then **Metrics**. Each button reports what it
   wrote.

   For your own class later: paste a Canvas discussion into a text file, drop it in
   `hermes/app/runtime/input/`, and put that filename in the path field.

2. **Profiles.** The roster lives at `hermes/app/runtime/roster.csv` (two
   columns: Sortable Name, User Login — the synthetic one is already there). Click
   **Write profiles** to have Hermes write one short, warm profile per student from
   how they participated.

3. **Pairing page.** Two ways to pair:
   - **Recommend dyads** reads a discussion and lists candidate pairs with a plain
     one-line reason for each ("why this pair"). The students appear under
     pseudonyms (S01, S02, …) because this view never touches names.
   - **Draft + pair** asks REALLMS to produce a paste-ready Canvas page that pairs
     your named students and tunes each pair's question. Enter a unit id (use
     **List units** to see them).

4. **Results.** Everything the steps above wrote shows up here. Click any file on
   the left to read it — profiles render as text, scores and metrics as tables, the
   pairing page as a preview. No hunting through folders.

That is one full pass. (The **Grades** step between Pairing page and Results
drafts 10-point grades and feedback from the parsed discussion; it follows
the same pattern.) For your own course,
replace the synthetic roster and discussion with your own local files and run
the same steps.

---

## If something goes wrong

Hermes tries to turn backend problems into plain instructions in the console. The
three you are most likely to hit:

- **A message about SWI-Prolog not being installed.** `swipl` is missing or not on
  your PATH. Finish step 1, then stop Hermes (`Ctrl-C`) and run
  `./hermes/app/launch.sh` again.
- **A message about no API key.** No REALLMS key is set. Do step 2 — click **Set
  key**, or add it to `runtime/.env`.
If a step prints a long error you do not recognize, the terminal window where you
ran `launch.sh` usually has more detail. Copy that text when you ask for help.
