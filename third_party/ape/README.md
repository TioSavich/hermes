# Attempto Parsing Engine runtime

This directory vendors the minimal Prolog runtime needed for
`ace_to_drs:acetext_to_drs/8` from
[Attempto/APE](https://github.com/Attempto/APE) at commit
`5f4d5354a45fb772763bf1a9543f508f15b28982`. A fresh interpreter's
`source_file/1` trace identifies the 20 runtime files under `prolog/`.

APE is distributed under LGPL-3.0-or-later. `LICENSE.txt` is the upstream
license file. The generated `grammar*.plp` files are upstream build outputs;
their contents are unmodified.

## Local compatibility change

`prolog/lexicon/lexicon_interface.pl` retains only APE's user-lexicon path.
The upstream common-lexicon import and fallback clauses were removed so this
runtime cannot load Clex. Clex is GPL-3.0 and is intentionally neither read nor
vendored here. Hermes supplies its generated Webster user lexicon instead.

No other vendored APE file is modified.
