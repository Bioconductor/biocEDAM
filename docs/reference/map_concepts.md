<div id="main" class="col-md-9" role="main">

# Map biological or medical concepts to ontology terms via OLS4

<div class="ref-description section level2">

Sends `query` to an ellmer chat that has EBI OLS4 search tools
registered, asking the LLM to identify concepts and retrieve the best
matching ontology terms. Returns a typed data frame conforming to
`TermMappingTable`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
map_concepts(
  query,
  provider = "anthropic",
  model = "claude-sonnet-4-5",
  temperature = 0,
  prompt = read_prompt("map_concepts.txt"),
  label_match = FALSE,
  chat = ols4_chat(provider = provider, model = model, temperature = temperature)
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   query:

    character(1) free-text input containing one or more biological or
    medical concepts.

-   provider:

    character(1) LLM provider; see `llm_env_var`. Defaults to
    `"anthropic"`.

-   model:

    character(1) model identifier for the chosen provider. Defaults to
    `"claude-sonnet-4-5"`.

-   temperature:

    numeric(1) sampling temperature; defaults to `0` for deterministic
    output. Ignored when `chat` is supplied directly.

-   prompt:

    character(1) instruction text sent to the LLM before the input text.
    Defaults to the contents of `inst/prompts/map_concepts.txt`; use
    `read_prompt("map_concepts.txt")` to inspect or customise.

-   label\_match:

    logical(1) if `TRUE`, adds `llm_label` and `label_match` columns via
    `ols4_enrich`, flagging rows where the LLM label and OLS4 canonical
    label share no content words (a sign of a hallucinated IRI).
    Defaults to `FALSE`.

-   chat:

    an ellmer `Chat` object with OLS4 tools already registered. When
    supplied, `provider`, `model`, and `temperature` are ignored. Build
    once with `ols4_chat` and reuse across calls to avoid restarting the
    bridge process each time.

</div>

<div class="section level2">

## Value

a data.frame with columns `input_text`, `term_label`, `term_iri`,
`obo_id`, `ontology`, `rationale`, `validated`, and `definition`, one
row per concept-term pair (plus `llm_label` and `label_match` when
`label_match=TRUE`). Filter on `validated == TRUE` to retain only
OLS4-confirmed terms.

</div>

<div class="section level2">

## Details

Each row is validated against the EBI OLS4 REST API via `ols4_enrich`:
rows whose `term_iri` cannot be found in OLS4 are dropped with a
warning, and an authoritative `definition` column is added alongside the
LLM-generated `rationale`.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive()) {
    # default provider (anthropic)
    map_concepts("spatial autocorrelation in gene expression")

    # switch provider
    map_concepts("chromatin accessibility",
                 provider = "openai", model = "gpt-4o")

    # reuse a pre-built chat across multiple calls
    ch <- ols4_chat()
    map_concepts("atrial fibrillation", chat = ch)
    map_concepts("whole genome sequencing", chat = ch)
}
```

</div>

</div>

</div>
