# Sidekick chat setup

The Sidekick chat page (`http://127.0.0.1:8765/sidekick.html`) runs a locally
tuned language model beside the Hermes knowledge base. Every part of it runs
on your machine; no network call leaves it.

The model is a gemma E2B checkpoint tuned on tool-calling sequences, quantized
to Q4_K_M, about 3.4 GB on disk. The page works without it — replies then come
from the knowledge base alone, and the page says that is what is happening —
but the chat demonstration needs the model file and llama.cpp.

## Before you begin

You need everything `hermes/mcp/SETUP.md` names (Python 3.10+, SWI-Prolog on
PATH), plus:

- **llama.cpp**, for the `llama-server` executable:

  ```sh
  brew install llama.cpp
  ```

- **The model file.** It is not tracked in git, so a fresh clone has none.
  Copy it from the person who shared the repository with you, to:

  ```
  hermes/app/runtime/experiments/sidekick/models/sidekick-Q4_K_M.gguf
  ```

  or set `HERMES_SIDEKICK_GGUF` to wherever you placed it. If a `.sha256`
  file came with the model, verify the checksum before first use:

  ```sh
  shasum -a 256 -c sidekick-Q4_K_M.gguf.sha256
  ```

## Run it

Two commands, in two terminals, from the repository root:

```sh
./hermes/app/launch.sh            # the console, on port 8765
./hermes/app/launch_sidekick.sh   # the model server, on port 8080
```

Then open `http://127.0.0.1:8765/sidekick.html`.

## What to expect

- The first consultation boots a Prolog worker and can take about eleven
  seconds. The page states this; later calls are much faster.
- While the console and the sidekick lane are both warm, two Prolog workers
  run. That is deliberate: a long chat turn must not block the other pages.
- Without the model file, the page still answers from the knowledge base and
  labels those answers as retrieval, not model prose.
- On a machine without a GPU (no Metal or CUDA), the model runs on CPU and is
  slow. The page still works; turns just take longer.
- The page has two modes. "Route decides" picks the tool deterministically
  and asks the model only to word the call. "Model decides" hands the model
  the same eight tools and lets you watch what it does and does not call.
