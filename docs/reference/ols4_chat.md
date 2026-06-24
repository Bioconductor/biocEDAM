<div id="main" class="col-md-9" role="main">

# Create an ellmer chat pre-wired with EBI OLS4 MCP tools

<div class="ref-description section level2">

Calls `ols4_mcp_tools` to retrieve the 12 OLS4 search tools, creates an
ellmer chat object via `llm_chat`, and registers all tools on the chat
so the LLM can invoke them during structured calls.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
ols4_chat(
  provider = "anthropic",
  model = "claude-sonnet-4-5",
  temperature = 0,
  url = "https://www.ebi.ac.uk/ols4/api/mcp",
  ...
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   provider:

    character(1) LLM provider; see `llm_env_var`. Defaults to
    `"anthropic"`.

-   model:

    character(1) model identifier. Defaults to `"claude-sonnet-4-5"`.

-   temperature:

    numeric(1) sampling temperature passed to the LLM. Defaults to `0`
    for deterministic, reproducible output.

-   url:

    character(1) OLS4 MCP endpoint URL passed to `ols4_mcp_tools`.

-   ...:

    additional arguments passed to `llm_chat`.

</div>

<div class="section level2">

## Value

an ellmer `Chat` object with all OLS4 tools registered.

</div>

<div class="section level2">

## Note

Starting the `mcp-remote` bridge takes a few seconds. Reuse the returned
object across multiple calls rather than creating a new one each time.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive()) {
    ch <- ols4_chat()
    map_concepts("chromatin accessibility and histone modification", chat = ch)
}
```

</div>

</div>

</div>
