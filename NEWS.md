# biocEDAM News

## 0.0.37

* Add `@return` documentation to all exported functions missing `\value` sections.
* Replace `sapply()` with `vapply()` throughout for type-safe iteration.
* Convert `=` to `<-` for assignment in key source files.
* Update R version dependency to 4.6.0.

## 0.0.36

* Add `@param` documentation for `nterms` in `flat_tagger` and `datf` in `verify`.
* Resave data files with xz compression (~600 KB saving).
* Add `@examples` to all exported functions.
* Add testthat unit tests (38 tests, no API key required).

## 0.0.34

* Fix non-ASCII characters in `edamize.R`: curly quotes in `cleantxt` replaced
  with `\u` escape sequences; em-dashes replaced with `--`.

## 0.0.33

* Add model/artifact mismatch guard in `retrieve_edam_candidates()`.

## 0.0.32

* Bundle pre-computed EDAM embeddings in `inst/demo_embedding/edam_embeddings.rds`.
* `get_edam_embeddings()` lookup order: `EDAM_EMBEDDING_RDS` env var, bundled
  file, AnnotationHub.

## 0.0.30

* Add embedding-based EDAM retrieval (RAG stage 1): `get_edam_embeddings()`,
  `make_edam_embeddings()`, `retrieve_edam_candidates()`.
* `edamize()` gains `retrieve_k` and `embed_model` parameters.
* Add `AnnotationHub` and `httr2` to Imports.

## 0.0.28

* Replace Python/curbioc path in `edamize()` with `ontoProc2` + ellmer.
  Connects to live EDAM SemanticSQL database; uses `chat_structured()` for
  term selection; eliminates JSON schema validation loop.
* `mkdf()` passes through a data.frame unchanged.
* Add `ontoProc2` and `DBI` to Imports.

## 0.0.22

* Generalise LLM provider support: `openai`, `anthropic`, `gemini`.
* New `R/llm_provider.R` with `llm_env_var()`, `llm_api_key()`, `llm_chat()`.
* All user-facing functions gain `provider=` parameter defaulting to
  `"anthropic"` with `model="claude-sonnet-4-5"`.
* `inst/curbioc/curbioc.py` refactored: lazy provider imports, `_complete()`
  dispatcher, `init_client()`.
