<div id="main" class="col-md-9" role="main">

# Retrieve the API key for an LLM provider from the environment

<div class="ref-description section level2">

Retrieve the API key for an LLM provider from the environment

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
llm_api_key(provider)
```

</div>

</div>

<div class="section level2">

## Arguments

-   provider:

    character(1) provider name; see `llm_env_var`

</div>

<div class="section level2">

## Value

character(1) the key value; empty string for keyless providers (e.g.
ollama)

</div>

<div class="section level2">

## Note

Stops with an informative error if the required environment variable is
not set.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
llm_api_key("ollama")  # always returns "" without checking any env var
#> [1] ""
if (nchar(Sys.getenv("ANTHROPIC_API_KEY")) > 0)
    llm_api_key("anthropic")
```

</div>

</div>

</div>
