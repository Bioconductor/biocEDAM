<div id="main" class="col-md-9" role="main">

# Generate and save EDAM term embeddings

<div class="ref-description section level2">

Connects to the current EDAM SemanticSQL release, fetches term labels
and definitions, embeds them using the specified provider, and saves the
result to `outfile`. The saved object can be submitted to AnnotationHub
or loaded directly via `get_edam_embeddings`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
make_edam_embeddings(
  outfile = file.path(tempdir(), "edam_embeddings.rds"),
  model = "text-embedding-3-small",
  provider = "openai"
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   outfile:

    character(1) path for the output `.rds` file. Defaults to
    `edam_embeddings.rds` in `tempdir()`.

-   model:

    character(1) embedding model identifier. For `provider="openai"` use
    e.g. `"text-embedding-3-small"`; for `provider="huggingface"` use a
    HuggingFace model ID such as `"FremyCompany/BioLORD-2023-C"`.

-   provider:

    character(1) embedding provider: `"openai"` (default) or
    `"huggingface"`. The corresponding environment variable must be set
    (see `llm_env_var`).

</div>

<div class="section level2">

## Value

invisibly, the embedding list (same structure as the AnnotationHub
resource returned by `get_edam_embeddings`).

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive() && nchar(Sys.getenv("OPENAI_API_KEY")) > 0) {
    out <- file.path(tempdir(), "edam_test.rds")
    emb <- make_edam_embeddings(outfile = out)
    cat("Terms embedded:", length(emb$ids), "\n")
    unlink(out)
}
```

</div>

</div>

</div>
