<div id="main" class="col-md-9" role="main">

# Map an LLM provider name to its environment variable

<div class="ref-description section level2">

Map an LLM provider name to its environment variable

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
llm_env_var(provider)
```

</div>

</div>

<div class="section level2">

## Arguments

-   provider:

    character(1) one of "openai", "anthropic", "claude", "gemini",
    "google", "ollama"

</div>

<div class="section level2">

## Value

character(1) environment variable name, or "" for keyless providers

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
llm_env_var("openai")
#> [1] "OPENAI_API_KEY"
llm_env_var("anthropic")
#> [1] "ANTHROPIC_API_KEY"
llm_env_var("ollama")   # "" — ollama needs no key
#> [1] ""
```

</div>

</div>

</div>
