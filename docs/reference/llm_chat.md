<div id="main" class="col-md-9" role="main">

# Create an ellmer chat object for a given LLM provider

<div class="ref-description section level2">

Create an ellmer chat object for a given LLM provider

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
llm_chat(provider = "openai", model, ...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   provider:

    character(1) provider name; see `llm_env_var`

-   model:

    character(1) model identifier appropriate for the chosen provider

-   ...:

    additional arguments passed to the underlying `chat_*` function

</div>

<div class="section level2">

## Value

an ellmer Chat object

</div>

<div class="section level2">

## Note

The `model` default in calling functions is typically an OpenAI model
name. When using a different provider, supply an appropriate model name
for that provider.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive() && nchar(Sys.getenv("ANTHROPIC_API_KEY")) > 0) {
    ch <- llm_chat("anthropic", model = "claude-haiku-4-5")
    ch$chat("Name one EDAM topic term.")
}
```

</div>

</div>

</div>
