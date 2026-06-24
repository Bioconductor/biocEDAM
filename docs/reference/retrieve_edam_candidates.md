<div id="main" class="col-md-9" role="main">

# Retrieve the top-k semantically closest EDAM terms per type

<div class="ref-description section level2">

Embeds `content` using the OpenAI API, computes cosine similarity
against a pre-computed EDAM embedding matrix, and returns the top
`retrieve_k` candidates per EDAM type (topic, operation, data, format).

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
retrieve_edam_candidates(
  content,
  edam_emb,
  retrieve_k = 75L,
  sim_threshold = 0.3,
  embed_model = edam_emb$model
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   content:

    character(1) text to use as the query (e.g. a package description).

-   edam\_emb:

    list as returned by `get_edam_embeddings` or `make_edam_embeddings`.

-   retrieve\_k:

    integer(1) number of candidates to keep per type.

-   sim\_threshold:

    numeric(1) minimum cosine similarity; candidates below this value
    are dropped before the LLM selection step. Defaults to 0.3.

-   embed\_model:

    character(1) embedding model; must match the model used to build
    `edam_emb`. Defaults to `edam_emb$model`.

</div>

<div class="section level2">

## Value

named list of data.frames (topic, operation, data, format), each with
columns `id` and `lbl`, ordered by descending cosine similarity to
`content`.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
# Model mismatch is caught before any API call
emb <- get_edam_embeddings()
#> Loading bundled EDAM embeddings from /private/var/folders/yw/gfhgh7k565v9w83x_k764wbc0000gp/T/RtmpMjVNCm/temp_libpathad7f6dc6f6fe/biocEDAM/demo_embedding/edam_embeddings.rds
tryCatch(
    retrieve_edam_candidates("some text", emb,
                             embed_model = "text-embedding-3-large"),
    error = function(e) conditionMessage(e)
)
#> [1] "embed_model 'text-embedding-3-large' does not match the artifact model 'text-embedding-3-small'.\nRun make_edam_embeddings(model = 'text-embedding-3-large') to generate a matching artifact."

if (interactive() && nchar(Sys.getenv("OPENAI_API_KEY")) > 0) {
    candidates <- retrieve_edam_candidates(
        "RNA-seq transcript quantification and metadata management",
        emb, retrieve_k = 5L)
    candidates$topic
}
```

</div>

</div>

</div>
