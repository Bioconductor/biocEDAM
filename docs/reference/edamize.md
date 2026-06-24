<div id="main" class="col-md-9" role="main">

# Assign EDAM ontology terms to text using a live SemanticSQL database and an LLM

<div class="ref-description section level2">

Assign EDAM ontology terms to text using a live SemanticSQL database and
an LLM

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
edamize(
  content_for_edam,
  provider = "anthropic",
  model = "claude-sonnet-4-5",
  nterms = 20L,
  prescrub = TRUE,
  prompt = read_prompt("edamize.txt"),
  retrieve_k = 75L,
  sim_threshold = 0.3,
  embed_model = "text-embedding-3-small",
  ...
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   content\_for\_edam:

    character(1) text describing a bioinformatics resource

-   provider:

    character(1) LLM provider; see `llm_env_var`. Defaults to
    "anthropic".

-   model:

    character(1) model identifier for the selected provider. Defaults to
    "claude-sonnet-4-5".

-   nterms:

    integer(1) approximate number of EDAM terms to select. Defaults
    to 20.

-   prescrub:

    logical(1) if TRUE apply `cleantxt` before processing. Defaults to
    TRUE.

-   prompt:

    character(1) instruction text sent to the LLM before the EDAM
    vocabulary tables and content. The string must contain one `%d`
    placeholder that will be replaced by `nterms`. Defaults to the
    contents of `inst/prompts/edamize.txt`; supply your own string to
    customise curation behaviour without editing package files.

-   retrieve\_k:

    integer(1) or NULL. When not NULL, use embedding-based retrieval
    (via `retrieve_edam_candidates`) to pre-filter the EDAM vocabulary
    to the top `retrieve_k` candidates per type before LLM selection.
    Requires `OPENAI_API_KEY` and the pre-computed embedding artifact
    (see `get_edam_embeddings`). Set to `NULL` to pass the full
    vocabulary directly to the LLM. Defaults to 75L.

-   sim\_threshold:

    numeric(1) minimum cosine similarity for a candidate term to be
    passed to the LLM. Terms below this threshold are dropped before the
    LLM selection step, reducing irrelevant tags. Only used when
    `retrieve_k` is not NULL. Defaults to 0.3.

-   embed\_model:

    character(1) OpenAI embedding model used for retrieval; must match
    the model used to build the artifact. Defaults to
    `"text-embedding-3-small"`.

-   ...:

    passed to `llm_chat`

</div>

<div class="section level2">

## Value

a data.frame with columns `uri` (full EDAM URI) and `tm` (term label),
restricted to confirmed vocabulary entries and deduplicated. Compatible
with `mkdf`, `toline`, and `edam_graph`.

</div>

<div class="section level2">

## Note

This function replaces the former Python/curbioc.py implementation. It
connects to the current EDAM release via `ontoProc2::semsql_connect()`
and selects terms using `chat_structured()` via ellmer, so no JSON
schema validation loop is needed and hallucinated term labels are
eliminated by post-filtering against the actual vocabulary.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# Input validation fires without any API key
tryCatch(edamize(list(a=1)), error = function(e) conditionMessage(e))
#> [1] "content_for_edam must be a single character string; did you mean to pass e.g. tst$focused?"

if (interactive() &&
    nchar(Sys.getenv("ANTHROPIC_API_KEY")) > 0 &&
    nchar(Sys.getenv("OPENAI_API_KEY")) > 0) {
  content <- readRDS(system.file("rds/tximetaFocused.rds", package="biocEDAM"))
  lk <- edamize(content$focused)   # retrieve_k=75 uses bundled embeddings
  print(lk)
  # Skip embedding retrieval and pass full vocabulary to the LLM:
  lk2 <- edamize(content$focused, retrieve_k = NULL)
  print(lk2)
}
```

</div>

</div>

</div>
